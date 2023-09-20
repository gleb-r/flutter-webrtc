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


public class VideoRecorder:NSObject, RTCVideoRenderer {
    private var videoTrack: RTCVideoTrack?
    
    private var videoWriter: AVAssetWriter?
    private var pixelBuffer: CVPixelBuffer?
    private var prevFramePixelBuffer: CVPixelBuffer?
    private var frameSize: CGSize?
    private var writerInput: AVAssetWriterInput?
    private var adapter: AVAssetWriterInputPixelBufferAdaptor?
    private var state = CaputureState.idle
    private var recordId: String?

    private var firstFrameTime: CFTimeInterval?
    private let eventChannel: FlutterEventChannel
    private var eventSink :FlutterEventSink?
    private let motionDetection: MotionDetection
    private var videoPathUrl: URL?
    private var rotation = RTCVideoRotation._0
    private var enableAudio = false
    private var dirPath: String?
    
    private static let TIME_SCALE: Int32 = 600
    
    
    
    @objc public init(binaryMessenger: FlutterBinaryMessenger, motionDetection: MotionDetection) {
        eventChannel = FlutterEventChannel(
            name: "FlutterWebRTC/detectionOnVideo",
            binaryMessenger: binaryMessenger)
        self.motionDetection = motionDetection
        super.init()
        eventChannel.setStreamHandler(self)
    }
    
    
    @objc public func startCapure(videoTrack: RTCVideoTrack,
                                  dirPath:String,
                                  enableAudio: Bool,
                                  result: FlutterResult?) {
        guard state == .idle else {
            result?(false)
            return
        }
        // TODO: enable audio
        
        self.videoTrack = videoTrack
        self.enableAudio = enableAudio
        let recordId = ProcessInfo.processInfo.globallyUniqueString
        let videoPath = URL(fileURLWithPath: dirPath).appendingPathComponent(recordId).appendingPathExtension("mp4")
        self.dirPath = dirPath
        NSLog("video path: \(videoPath.path)")
        do {
            videoWriter = try AVAssetWriter.init(outputURL: videoPath, fileType: AVFileType.mp4)
        } catch {
            result?(FlutterError(code: "failed to create writer",
                                message: error.localizedDescription,
                                details: nil))
            return
        }
        videoTrack.add(self)
        self.videoPathUrl = videoPath
        self.recordId = recordId
        self.state = .start
        result?(true)
    }
    
    @objc public func stopCapure(result:  @escaping FlutterResult) {
        guard state == .capturing else  {
            disposeRecording()
            result(result(FlutterError(code: "Stop error, wrong state",
                                       message: "state : \(state)",
                                       details: nil)))
            return
        }
        NSLog("Stop rec inner")
        
        guard let videoUrl = self.videoPathUrl, let recordId = self.recordId else {
            NSLog("Can't stop, Video path or recordId is nil")
            result( FlutterError(code: "Stop error",
                                 message: "Video path is nil",
                                 details: nil))
            return
        }
        guard writerInput?.isReadyForMoreMediaData == true else {
            NSLog("Can't stop, writer is not ready for more data")
            result(
                FlutterError(code: "Stop error",
                             message: "writer is not ready for more data",
                             details: nil)
            )
            return
        }
        videoTrack?.remove(self)
        motionDetection.removeLister()
        writerInput?.markAsFinished()
        var writerError = false
        videoWriter?.finishWriting { [weak self] in
            guard let self = self, let writer = self.videoWriter else { return }
            if writer.status == .failed {
                writerError = true
                // TODO: send by event channel
                NSLog("Video writing failed: %@", writer.error?.localizedDescription ?? "")
                result(FlutterError(code: "Stop error",
                                    message: "writer status is failed",
                                    details: nil))
            } else {
                NSLog("Video witing fished with: %@", writer.status.rawValue)
            }
        }
        
        let durationMs: Int
        if let firstFrameTime = firstFrameTime {
            durationMs = Int((CACurrentMediaTime() - firstFrameTime) * 1000)
        } else { durationMs = 0 }
        let recResult = RecordingResult(
            recordId: recordId,
            videoPath: videoUrl.path,
            durationMs: durationMs,
            frameInterval: motionDetection.frameIntervalMs,
            rotationDegree: rotation.rawValue)
        
        if !writerError {
            NSLog("send rec result")
            result(recResult.toMap())
        }
        disposeRecording()
        NSLog("Video result sent")
    }
    
    private func restartRecording() {
        guard let videoTrack = self.videoTrack, let dirPath = self.dirPath else {
            NSLog("Can't restart, videoTrack is nil")
            return
        }
        self.state = .idle
        NSLog("restart recording")
        
        writerInput?.markAsFinished()
        NSLog("Writer marked as finished")
        var writerError = false
        videoWriter?.finishWriting {  }
        adapter = nil
        videoWriter = nil
        writerInput = nil
        adapter = nil
        firstFrameTime = nil
        startCapure(videoTrack: videoTrack,
                    dirPath: dirPath,
                    enableAudio: self.enableAudio,
                    result: nil)
        
        NSLog("Resturt finished")
        
    }
    
    private func disposeRecording() {
        frameSize = nil
        adapter = nil
        videoTrack = nil
        videoWriter = nil
        adapter = nil
        firstFrameTime = nil
        self.videoPathUrl = nil
        self.recordId = nil
        self.dirPath = nil
        self.state = .idle
    }
    
    public func setSize(_ size: CGSize) {
        if let frameSize = self.frameSize, frameSize != size {
            NSLog("frame size changed prev: \(frameSize), new: \(size)")
            // TODO: stop recording and start again
        }
        self.frameSize = size
    }
    
    public func renderFrame(_ frame: RTCVideoFrame?) {
        switch(state) {
        case .idle: return
        case .start: initialize()
        case .capturing: addFrame(frame: frame)
        }
    }
    
    private func initialize() {
       
        guard let frameSize = self.frameSize else { return }
        createWriter(size: frameSize)
        createBuffer(size: frameSize)
        motionDetection.addListener(listener: self)
        state = .capturing
        NSLog("init finished")
    }
    
    private func addFrame(frame: RTCVideoFrame?) {
        guard let frame = frame,
              let pixelBuffer = self.pixelBuffer,
              let writer = writerInput,
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
        if let videoWriter = self.videoWriter, videoWriter.status == .failed  {
            NSLog("Writer status: failed, frame skipped")
            restartRecording()
            return
        }
        pixelBuffer.copy(from: frame)
        adapter?.append(pixelBuffer, withPresentationTime: persentedTime)
    }
    
    
    private func createWriter(size: CGSize) {
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber.init(value: size.width),
            AVVideoHeightKey: NSNumber.init(value: size.height)
        ]
        let writerInput = AVAssetWriterInput.init(mediaType: AVMediaType.video, outputSettings: settings)
        self.writerInput = writerInput
        self.adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput)
        guard let writer = self.videoWriter else {
            fatalError("video writer is nil")
        }
        assert(adapter != nil)
        assert(writer.canAdd(writerInput))
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)
        NSLog("Writer created for size: \(size), status: \(writer.status)")
    }
    
    private func createBuffer(size: CGSize) {
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(size.width),
                            Int( size.height),
                            kCVPixelFormatType_32BGRA,
                            nil,
                            &pixelBuffer)
    }
    
    private func createPrevBuffer(size: CGSize) {
        let pixelAttr:NSDictionary = [kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()]
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(size.width),
                            Int( size.height),
                            kCVPixelFormatType_32BGRA,
                            pixelAttr,
                            &prevFramePixelBuffer)
    }
}

private enum CaputureState {
    case idle, start, capturing
}


extension VideoRecorder: MotionDetectionListener {
    func onDetected(result: DetectionResult) {
        guard let firstFrameTime = firstFrameTime else {
            return
        }
        let frameIntervalMs = motionDetection.frameIntervalMs
        let frameIndex = Int((CACurrentMediaTime() - firstFrameTime) * 1000) / frameIntervalMs
        let frame = DetectionWithTime(
            squaresList: result.detectedList,
            frameIndex: frameIndex,
            aspect: result.aspectRatio,
            xSqCount: result.xCount,
            ySqCount: result.yCount)
        DispatchQueue.main.async { [weak self] in
            guard let eventSink = self?.eventSink else { return}
            eventSink(frame.toMap())
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
}


extension RTCI420BufferProtocol {
    func correctRotation(rotation: RTCVideoRotation) -> RTCI420BufferProtocol {
        let rotatedWidth: Int32
        let rotatedHeght: Int32
        if rotation == ._90 || rotation == ._270 {
            rotatedWidth = self.height
            rotatedHeght = self.width
        } else {
            rotatedHeght = self.height
            rotatedWidth = self.width
        }
        let buffer = RTCI420Buffer.init(width: rotatedWidth, height: rotatedHeght)
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
            width: self.height,
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
                              width: i420Buf.height)
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
