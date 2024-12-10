//
//  VideoRecorder.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 16.06.2022.
//

import Foundation
import WebRTC
import Flutter
import CoreVideo
import AVFoundation
import OSLog
import flutter_webrtc

public class VideoRecorder:NSObject {
    private var videoTrack: RTCVideoTrack?
    private var audioTrack: RTCAudioTrack?

    private var mediaWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var pixelBuffer: CVPixelBuffer?
    private var frameSize: CGSize?
    private var adapter: AVAssetWriterInputPixelBufferAdaptor?

    private var recordId: String?
    private var audioSink: FlutterRTCAudioSink?

    private var firstFrameTime: CFTimeInterval?
    private let eventChannel: FlutterEventChannel
    private var eventSink :FlutterEventSink?
    private let motionDetection: MotionDetection
    private var rotation = RTCVideoRotation._0
    private var enableAudio = false
    private var path: String?
    private var shouldStop = false
    private var isLocalTrack = false
    private var detectionData: DetectionData?
    private var startVoiceTime: CMTime?

    private static let TIME_SCALE: Int32 = 600

    private var log =  Log(subsystem: "Recording", category: "")
    private var state = RecorderState.idle {
        didSet {
            guard state != oldValue else { return }
            log.d("State changed: \(state)")
            let eventType = RecordEventType.from(state)
            sendEvent(event: RecordEvent(type: eventType, data: nil))
        }
    }

    // Add for recording using device's micro
    private var audioEngine: AVAudioEngine?
    private var audioFormat: AVAudioFormat?

    @objc public init(binaryMessenger: FlutterBinaryMessenger, motionDetection: MotionDetection) {
        eventChannel = FlutterEventChannel(
            name: "FlutterWebRTC/detectionOnVideo",
            binaryMessenger: binaryMessenger)
        self.motionDetection = motionDetection
        super.init()
        eventChannel.setStreamHandler(self)
    }

    @objc public func startCapure(videoTrack: RTCVideoTrack,
                                  audioTrack: RTCAudioTrack?,
                                  recordId : String,
                                  path:String,
                                  enableAudio: Bool,
                                  isLocalTrack: Bool,
                                  result: FlutterResult?) {
        log.d("Start capture called")
        guard state == .idle else {
            result?(false)
            return
        }
        let pathUrl = URL(fileURLWithPath: path)
        result?(true)
        self.videoTrack = videoTrack
        self.isLocalTrack = isLocalTrack
        self.audioTrack = audioTrack
        self.enableAudio = enableAudio
        self.recordId = recordId
        self.path = path
        log.d("Video path: \(path)")
        do {
            self.mediaWriter = try AVAssetWriter.init(outputURL: pathUrl, fileType: AVFileType.mp4)
        } catch {
            self.sendError( FlutterError(code: "failed to create writer",
                                         message: error.localizedDescription,
                                         details: nil))
            self.disposeRecording()
            return
        }
        videoTrack.add(self)
        self.recordId = recordId
        self.state = .start
    }

    @objc public func stopCapure(result:  @escaping FlutterResult) {
        log.d("Stop capture called")
        if state == .initialazing {
            shouldStop = true
            return
        }

        guard state == .capturing else  {
            disposeRecording()
            // TODO: send error through event channel
            result(FlutterError(code: "Stop error, wrong state",
                                message: "state : \(state)",
                                details: nil))
            return
        }
        log.d("Stop rec inner")
        state = .stop
        guard let videoPath = self.path, let recordId = self.recordId else {
            log.e("Can't stop, Video path or recordId is nil")
            sendError(FlutterError(code: "Stop error",
                                   message: "Video path is nil",
                                   details: nil))
            disposeRecording()
            return
        }
        guard let mediaWriter = self.mediaWriter else {
            log.e("Can't stop, mediaWriter is nil")
            sendError(FlutterError(code: "Stop error",
                                   message: "mediaWriter is nil",
                                   details: nil))
            disposeRecording()
            return
        }
        guard videoWriterInput?.isReadyForMoreMediaData == true else {
            log.e("Can't stop, writer is not ready for more data")
            sendError(FlutterError(code: "Stop error",
                                   message: "writer is not ready for more data",
                                   details: nil))
            disposeRecording()
            return
        }
        self.motionDetection.removeLister()

        Task(priority: .background) { [weak self] in
            guard let self = self else { return }
            self.videoTrack?.remove(self)
            self.videoWriterInput?.markAsFinished()
            self.audioWriterInput?.markAsFinished()
            self.stopAudioCapture()
            let durationMs: Int
            if let firstFrameTime = self.firstFrameTime {
                durationMs = Int((CACurrentMediaTime() - firstFrameTime) * 1000)
            } else { durationMs = 0 }
            await mediaWriter.finishWriting()
            guard mediaWriter.status != .failed else {
                self.log.e("Video writing failed:\(mediaWriter.error?.localizedDescription ?? "")")
                self.sendError(FlutterError(code: "Stop error",
                                            message: "writer status is failed",
                                            details: nil))
                self.disposeRecording()
                return
            }
            let status = mediaWriter.status
            self.log.d("Video writing fished with:\(status)")
            self.detectionData?.duration = durationMs
            let recResult = RecordingResult(
                recordId: recordId,
                videoPath: videoPath,
                durationMs: durationMs,
                rotationDegree: self.rotation.rawValue,
                detectionData: self.detectionData
            )
            self.log.d("Send rec result")
            self.sendEvent(event: RecordEvent(
                type: .result,
                data: recResult.toJson())
            )
            self.disposeRecording()
        }
        result(true)
    }

    private func stopWithoutSaving() async -> Void {
        log.d("Stop without saving")
        videoTrack?.remove(self)
        motionDetection.removeLister()
        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        stopAudioCapture()
        await mediaWriter?.finishWriting()
        disposeRecording()
    }

    private func restartRecording() {
        guard let videoTrack = self.videoTrack,
              let path = self.path,
              let recordId = self.recordId
        else {
            log.e("Can't restart, videoTrack is nil")
            return
        }
        self.state = .idle
        log.w("restart recording")

        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        log.d("Writer marked as finished")
        mediaWriter?.finishWriting {  }
        adapter = nil
        mediaWriter = nil
        videoWriterInput = nil
        audioWriterInput = nil
        adapter = nil
        firstFrameTime = nil
        closeAudioSink()
        startCapure(videoTrack: videoTrack,
                    audioTrack: audioTrack,
                    recordId: recordId,
                    path: path,
                    enableAudio: self.enableAudio,
                    isLocalTrack: self.isLocalTrack,
                    result: nil)

        log.d("Restart finished")
    }

    private func closeAudioSink() {
      audioSink?.bufferCallback = nil
      audioSink?.close()
      audioSink = nil
    }
    
    private func disposeRecording() {
        self.frameSize = nil
        self.adapter = nil
        self.videoTrack = nil
        self.mediaWriter = nil
        self.adapter = nil
        self.firstFrameTime = nil
        self.path = nil
        self.recordId = nil
        self.state = .idle
        self.shouldStop = false
        self.detectionData = nil
        self.audioEngine = nil
        self.audioFormat = nil
    }

    public func setSize(_ size: CGSize) {
        if let frameSize = self.frameSize, frameSize != size {
            log.w("frame size changed prev: \(frameSize), new: \(size)")
            // TODO: send event to restart on orientation change
            // TODO: ideally continue recording on camera orientation change
            stopCapure(result: { _ in })
            return
        }
        self.frameSize = size
    }

    /// heavy operation takes about 3 sec
    private func initialize() {
        log.d("Initialize started")
        guard let frameSize = self.frameSize else { return }

        state = .initialazing
        Task(priority: .background) {
            await self.createVideoWriter(size: frameSize)
            if (self.enableAudio) {
                if self.isLocalTrack {
                    await self.createAudioWriterViaMicro()
                } else {
                    await self.createAudioWriterViaRtcTrack()
                }
            }
            await self.startWriting()
            await self.createBuffer(size: frameSize)
            self.motionDetection.addListener(listener: self)
            self.state = .capturing
            self.log.d("Initialize finished")
            if self.shouldStop {
                self.log.d("disposing after init")
                await self.stopWithoutSaving()
            }

        }
    }

    /// heavy operation takes about 2 sec
    private func startWriting() async -> Void {
        guard let mediaWriter = self.mediaWriter else {
            log.e("mediaWriter is nil")
            return
        }
        mediaWriter.startWriting()
        mediaWriter.startSession(atSourceTime: CMTime.zero)
        self.startVoiceTime = CMClockGetTime(CMClockGetHostTimeClock())
    }

    /// heavy operation takes about 1 sec
    private func createAudioWriterViaRtcTrack() async -> Void {
        log.d("create audio writer")
        guard let audioTrack = self.audioTrack else {
            log.e("audioTrack is nil")
            return
        }
        audioSink = FlutterRTCAudioSink.init(audioTrack: audioTrack)
        log.d("Audio sink created")

        guard let audioSink = self.audioSink else { return }
        var acl = AudioChannelLayout()
        memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono

        let audioSettings: [String: Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100.0,
            AVChannelLayoutKey: NSData(bytes: &acl, length: MemoryLayout<AudioChannelLayout>.size),
            AVEncoderBitRateKey: 64000
        ]

        self.audioWriterInput = AVAssetWriterInput.init(
            mediaType: AVMediaType.audio,
            outputSettings: audioSettings,
            sourceFormatHint: audioSink.format
        )
        guard let audioWriterInput = self.audioWriterInput else {
            log.e("AudioWriterInput is nil")
            return
        }
        guard let mediaWriter = self.mediaWriter else {
            log.e("mediaWriter is nil")
            return
        }
        audioWriterInput.expectsMediaDataInRealTime = true

        mediaWriter.add(audioWriterInput)
        audioSink.bufferCallback = { [weak self] buffer in
            guard let buffer = buffer else {
                self?.log.e("Audio buffer is nil")
                return
            }
            if  audioWriterInput.isReadyForMoreMediaData {
                audioWriterInput.append(buffer)
            }
        }
        log.d("Audio writer created")
    }

   private func createAudioWriterViaMicro() async {
       log.d("create audio writer from mic")
       guard let mediaWriter = self.mediaWriter else {
           log.e("mediaWriter is nil")
           return
       }

       let audioSession = AVAudioSession.sharedInstance()
       do {
           try audioSession.setCategory(
               .playAndRecord,
               mode: .default,
               options: [.defaultToSpeaker, .allowBluetooth]
           )
           try audioSession.setActive(true)
       } catch {
           log.e("Failed to configure AVAudioSession: \(error)")
       }

       var acl = AudioChannelLayout()
       memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
       acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono

       let audioSettings: [String: Any] = [
           AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
           AVNumberOfChannelsKey: 1,
           AVSampleRateKey: 44100.0,
           AVChannelLayoutKey: NSData(bytes: &acl, length: MemoryLayout<AudioChannelLayout>.size),
           AVEncoderBitRateKey: 64000
       ]

       self.audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
       guard let audioWriterInput = self.audioWriterInput else {
           log.e("AudioWriterInput is nil")
           return
       }
       audioWriterInput.expectsMediaDataInRealTime = true
       mediaWriter.add(audioWriterInput)

       let audioEngine = AVAudioEngine()
       self.audioEngine = audioEngine

       let inputNode = audioEngine.inputNode
       let inputFormat = inputNode.inputFormat(forBus: 0)

       let asbdPointer = inputFormat.streamDescription
       let asbd = asbdPointer.pointee

       var audioFormatDescription: CMAudioFormatDescription?
       var localAsbd = asbd
       let statusDesc = CMAudioFormatDescriptionCreate(
           allocator: kCFAllocatorDefault,
           asbd: &localAsbd,
           layoutSize: 0,
           layout: nil,
           magicCookieSize: 0,
           magicCookie: nil,
           extensions: nil,
           formatDescriptionOut: &audioFormatDescription
       )
       if statusDesc != noErr {
           log.e("Failed to create CMAudioFormatDescription")
           return
       }

       // Listen to micro
       inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self, audioFormatDescription, asbd] (buffer, when) in
           let installTapStartTime = CFAbsoluteTimeGetCurrent()
           guard let self = self,
                 let audioWriterInput = self.audioWriterInput,
                 audioWriterInput.isReadyForMoreMediaData,
                 let audioFormatDescription = audioFormatDescription,
                 let startVoiceTime = self.startVoiceTime else { return }

           let nowHostTime = CMClockGetTime(CMClockGetHostTimeClock())
           let elapsed = CMTimeSubtract(nowHostTime, startVoiceTime)

           let samplesCount = CMItemCount(buffer.frameLength)

           let dataPtr = buffer.audioBufferList.pointee.mBuffers.mData
           let dataSize = Int(buffer.audioBufferList.pointee.mBuffers.mDataByteSize)
           guard let dataPtrSafe = dataPtr else { return }

           var blockBuffer: CMBlockBuffer?
           let statusBlock = CMBlockBufferCreateWithMemoryBlock(
               allocator: kCFAllocatorDefault,
               memoryBlock: nil,
               blockLength: dataSize,
               blockAllocator: nil,
               customBlockSource: nil,
               offsetToData: 0,
               dataLength: dataSize,
               flags: 0,
               blockBufferOut: &blockBuffer
           )

           if statusBlock == kCMBlockBufferNoErr, let bb = blockBuffer {
               CMBlockBufferReplaceDataBytes(with: dataPtrSafe, blockBuffer: bb, offsetIntoDestination: 0, dataLength: dataSize)
               let sampleRate = asbd.mSampleRate
               let duration = CMTimeMake(value: Int64(samplesCount), timescale: Int32(sampleRate))

               var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo(
                   duration: duration,
                   presentationTimeStamp: elapsed,
                   decodeTimeStamp: CMTime.invalid
               )
               var sampleBuffer: CMSampleBuffer?
               let statusSamp = CMSampleBufferCreateReady(
                   allocator: kCFAllocatorDefault,
                   dataBuffer: bb,
                   formatDescription: audioFormatDescription,
                   sampleCount: samplesCount,
                   sampleTimingEntryCount: 1,
                   sampleTimingArray: &timingInfo,
                   sampleSizeEntryCount: 0,
                   sampleSizeArray: nil,
                   sampleBufferOut: &sampleBuffer
               )

               if statusSamp == noErr, let sb = sampleBuffer {
                   audioWriterInput.append(sb)
               }
           }
       }

       do {
           try audioEngine.start()
       } catch {
           log.e("Failed to start audio engine: \(error)")
           sendError(FlutterError(code: "AudioEngineStartError", message: error.localizedDescription, details: nil))
       }

       log.d("Audio writer (mic) created")
   }

    private func stopAudioCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    private func addFrame(frame: RTCVideoFrame?) {
        guard let frame = frame,
              let pixelBuffer = self.pixelBuffer,
              let writer = videoWriterInput,
              writer.isReadyForMoreMediaData else {
            return
        }
        let frameTime = CACurrentMediaTime()
        let currentFrameNumer: Int64
        if let firstFrameTime = firstFrameTime {
            currentFrameNumer = Int64((frameTime - firstFrameTime) * Double(Self.TIME_SCALE))
        } else {
            firstFrameTime = frameTime
            self.rotation = frame.rotation
            currentFrameNumer = 0
        }
        let persentedTime = CMTimeMake(value: currentFrameNumer,
                                       timescale: Self.TIME_SCALE)
        if let mediaWriter = self.mediaWriter, mediaWriter.status == .failed  {
            log.e("Writer status: failed, frame skipped")
            restartRecording()
            return
        }
        pixelBuffer.copy(from: frame)
        adapter?.append(pixelBuffer, withPresentationTime: persentedTime)
        // TODO: for first frame from start return started event
    }

    private func createVideoWriter(size: CGSize) async -> Void {
        log.d("Create video writer")
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber.init(value: size.width),
            AVVideoHeightKey: NSNumber.init(value: size.height)
        ]
        let writerInput = AVAssetWriterInput.init(mediaType: AVMediaType.video, outputSettings: settings)
        self.videoWriterInput = writerInput
        self.adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput)
        guard let writer = self.mediaWriter else {
            fatalError("video writer is nil")
        }
        assert(adapter != nil)
        assert(writer.canAdd(writerInput))
        writer.add(writerInput)
        log.d("Writer created for size: \(size), status: \(writer.status)")
    }

    private func createBuffer(size: CGSize) async -> Void {
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(size.width),
                            Int(size.height),
                            kCVPixelFormatType_32BGRA,
                            nil,
                            &pixelBuffer)
    }
}

enum RecorderState {
    case idle,
         start,
         initialazing,
         capturing,
         stop
}


extension VideoRecorder: MotionDetectionListener {
    func onDetected(result: DetectionFrame) {
        guard let firstFrameTime = firstFrameTime else {
            return
        }
        let frameIntervalMs = motionDetection.frameIntervalMs
        let frameIndex = Int((CACurrentMediaTime() - firstFrameTime) * 1000) / frameIntervalMs
        if detectionData == nil {
            detectionData = DetectionData.init(
                detectionFrame: result,
                frameIndex: frameIndex,
                frameIntervalMs: frameIntervalMs
            )
        } else {
            do {
                try detectionData?.addDetection(detection: result, frameIndex: frameIndex)
            } catch {
                log.e("\(error)")
                sendError(FlutterError(code: "Add Detection error",
                                       message: error.localizedDescription,
                                       details: nil))
            }
        }
    }
}


extension VideoRecorder: FlutterStreamHandler {

    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            eventSink = events
            return nil
        }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func sendError(_ error: FlutterError) {
        sendEvent(event: RecordEvent(type: .error, data: error.toJson()))
    }

    private func sendEvent(event:RecordEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let eventSink = self?.eventSink else { return}
            eventSink(event.toJson())
            self?.log.d("Send event: \(event.type.rawValue)")
        }
    }
}

extension VideoRecorder: RTCVideoRenderer {
    public func renderFrame(_ frame: RTCVideoFrame?) {
        switch(state) {
        case  .idle , .initialazing, .stop: return
        case .start: initialize()
        case .capturing: addFrame(frame: frame)
        }
    }
}


extension RTCI420BufferProtocol {
    func correctRotation(rotation: RTCVideoRotation) -> RTCI420BufferProtocol {
        let rotatedWidth: Int32
        let rotatedHeight: Int32
        if rotation == ._90 || rotation == ._270 {
            rotatedWidth = self.height
            rotatedHeight = self.width
        } else {
            rotatedHeight = self.height
            rotatedWidth = self.width
        }
        let buffer = RTCI420Buffer.init(width: rotatedWidth, height: rotatedHeight)
        RTCYUVHelper.i420Rotate(
            self.dataY,
            srcStrideY: strideY,
            srcU: dataU,
            srcStrideU: strideU,
            srcV: dataV,
            srcStrideV: strideV,
            dstY: UnsafeMutablePointer(mutating: buffer.dataY),
            dstStrideY: buffer.strideY,
            dstU: UnsafeMutablePointer(mutating:buffer.dataU),
            dstStrideU: buffer.strideU,
            dstV: UnsafeMutablePointer(mutating:buffer.dataV),
            dstStrideV: buffer.strideV,
            width: self.width,
            height: self.height,
            mode: rotation)
        return buffer
    }

}

extension CVPixelBuffer {
    func copy(from frame:RTCVideoFrame) {
        let i420Buf = frame.buffer.toI420().correctRotation(rotation: frame.rotation)
        CVPixelBufferLockBaseAddress(self, .readOnly)
        let pixelFormat: OSType = CVPixelBufferGetPixelFormatType(self)
        if pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
            pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {

            let dstY = CVPixelBufferGetBaseAddressOfPlane(self, 0)
            let dstYStride = CVPixelBufferGetBytesPerRowOfPlane(self, 0)
            let dstUV = CVPixelBufferGetBaseAddressOfPlane(self, 1)
            let dstUYStride = CVPixelBufferGetBytesPerRowOfPlane(self, 1)
            RTCYUVHelper.i420(toNV12: i420Buf.dataY,
                              srcStrideY: i420Buf.strideY,
                              srcU: i420Buf.dataU,
                              srcStrideU: i420Buf.strideU,
                              srcV: i420Buf.dataV,
                              srcStrideV: i420Buf.strideV,
                              dstY: dstY,
                              dstStrideY: Int32(dstYStride),
                              dstUV: dstUV,
                              dstStrideUV: Int32(dstUYStride),
                              width: i420Buf.width,
                              height: i420Buf.height)
        } else {
            let dst = CVPixelBufferGetBaseAddress(self)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
            if pixelFormat == kCVPixelFormatType_32BGRA {
                RTCYUVHelper.i420(toARGB: i420Buf.dataY,
                                  srcStrideY: i420Buf.strideY,
                                  srcU: i420Buf.dataU,
                                  srcStrideU: i420Buf.strideU,
                                  srcV: i420Buf.dataV,
                                  srcStrideV: i420Buf.strideV,
                                  dstARGB: dst,
                                  dstStrideARGB: Int32(bytesPerRow),
                                  width: i420Buf.width,
                                  height: i420Buf.height)
            } else if pixelFormat == kCVPixelFormatType_32ARGB {
                RTCYUVHelper.i420(toBGRA: i420Buf.dataY,
                                  srcStrideY: i420Buf.strideY,
                                  srcU: i420Buf.dataU,
                                  srcStrideU: i420Buf.strideU,
                                  srcV: i420Buf.dataV,
                                  srcStrideV: i420Buf.strideV,
                                  dstBGRA: dst,
                                  dstStrideBGRA: Int32(bytesPerRow),
                                  width: i420Buf.width,
                                  height: i420Buf.height)
            }
        }
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
    }
}