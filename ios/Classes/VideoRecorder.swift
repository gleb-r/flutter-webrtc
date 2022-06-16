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
    private var frameSize: CGSize?
    private var writerInput: AVAssetWriterInput?
    private var adapter: AVAssetWriterInputPixelBufferAdaptor?
    private var started = false
    private var writerCreated = false
    private var i: Int64 = 0
    
    @objc public override init() {
        super.init()
    }
    
    
    @objc public func startCapure(videoTrack: RTCVideoTrack, topPath path: String, result: FlutterResult) {
        guard !started else {
            result(false)
            return
        }
        self.started = true
        self.videoTrack = videoTrack
        let url = URL.init(fileURLWithPath: path)
        do {
            videoWriter = try AVAssetWriter.init(outputURL: url, fileType: AVFileType.mp4)
        } catch {
            result(FlutterError(code: "failed to create writer", message: error.localizedDescription, details: nil))
            return
        }
        videoTrack.add(self)
        result(true)
    }
    
    @objc public func stopCapure(result: FlutterResult) {
        guard started else {
            result(false)
            return
        }
        videoTrack?.remove(self)
        writerInput?.markAsFinished()
        writerCreated = false
        videoWriter?.finishWriting { [weak videoWriter] in
            guard let writer = videoWriter else { return }
            if writer.status == .failed {
                NSLog("Video writing failed: %@", writer.error?.localizedDescription ?? "")
            }
        }
        
        adapter = nil
        started = false
        videoTrack = nil
        videoWriter = nil
        adapter = nil
        result(true)
        
        
    }
    
    public func setSize(_ size: CGSize) {
        if !writerCreated {
            createWriter(size: size)
        }
        if pixelBuffer == nil || self.frameSize != size {
            createBuffer(size: size)
        }
        self.frameSize = size
    }
    
    public func renderFrame(_ frame: RTCVideoFrame?) {
        guard started, let frame = frame,
              let pixelBuffer = self.pixelBuffer,
              let writer = writerInput,
              writer.isReadyForMoreMediaData else {
            return
        }
        let persentedTime = CMTimeMake(value: i * 25, timescale: 600)
        i += 1
        pixelBuffer.copy(from: frame)
        adapter?.append(pixelBuffer, withPresentationTime: persentedTime)
        
    }
    
    private func createWriter(size: CGSize) {
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber.init(value: size.width),
            AVVideoHeightKey: NSNumber.init(value: size.height)
        ]
        let writerInput = AVAssetWriterInput.init(mediaType: AVMediaType.video, outputSettings: settings)
        self.writerInput = writerInput
        self.adapter = AVAssetWriterInputPixelBufferAdaptor.init(assetWriterInput: writerInput)
        guard let writer = self.videoWriter else {
            fatalError("video writer is nil")
        }
        assert(adapter != nil)
        assert(writer.canAdd(writerInput))
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)
        i = 0
        writerCreated = true
    }
    
    private func createBuffer(size: CGSize) {
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(size.width),
                            Int( size.height),
                            kCVPixelFormatType_32BGRA,
                            nil,
                            &pixelBuffer)
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
            dstStrideV: buffer.strideV, width: self.width, width: self.height, mode: rotation)
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
                              srcU: i420Buf.dataU, srcStrideU: i420Buf.strideU,
                              srcV: i420Buf.dataV, srcStrideV: i420Buf.strideV,
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
                RTCYUVHelper.i420(toABGR: i420Buf.dataY,
                                  srcStrideY: i420Buf.strideY,
                                  srcU: i420Buf.dataU,
                                  srcStrideU: i420Buf.strideU,
                                  srcV: i420Buf.dataV,
                                  srcStrideV: i420Buf.strideV,
                                  dstABGR: dst,
                                  dstStrideABGR: Int32(bytesPerRow),
                                  width: i420Buf.width,
                                  height: i420Buf.height)
            } else if pixelFormat == kCVPixelFormatType_32ARGB { // TODO: chage to BGRA?
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
