//
//  MotionDetection.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

import Foundation
import WebRTC

public class MotionDetection: NSObject, RTCVideoRenderer {
    
    private lazy var pixelDetection = { PixelDetection() }()
    private var detectionLevel = 0
    private var frameSize: CGSize?
    private let eventChannel: FlutterEventChannel
    private var eventSink :FlutterEventSink?
    private var videoTrack: RTCVideoTrack?
    private var previosTime = CACurrentMediaTime()
    private var detectionInterval: Double = 0.2
    private var started = false
    
    @objc public init(binaryMessenger: FlutterBinaryMessenger) {
        eventChannel = FlutterEventChannel(
            name: "FlutterWebRTC/motionDetection",
            binaryMessenger: binaryMessenger)
        super.init()
        eventChannel.setStreamHandler(self)
    }
    
    
    @objc public func setDetection(videoTrack: RTCVideoTrack,
                                   request: DetectionRequest
    ) {
        if !request.enabled {
            stop();
        } else if !started {
            start(videoTrack: videoTrack)
        } else {
            setDetectionParams(request: request)
        }
    }
    
    
    private func start(videoTrack: RTCVideoTrack) {
        self.started = true
        videoTrack.add(self)
        self.videoTrack = videoTrack
    }
    
    @objc public func stop() {
        videoTrack?.remove(self)
        self.videoTrack = nil
        self.started = false
        self.pixelDetection.resetPrevious()
    }
    
    @objc public func setDetectionParams(request: DetectionRequest) {
        self.detectionLevel = request.level
    }
    
    
    public func setSize(_ size: CGSize) {
        self.frameSize = size
    }
    
    public func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else {
            return
        }
        let currentTime = CACurrentMediaTime()
        if (currentTime - previosTime > CFTimeInterval(detectionInterval)) {
            previosTime = currentTime
            let buffer = frame.buffer.toI420()
            
            let rotation = frame.rotation
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }
                self.pixelDetection.detect(
                    buffer: buffer,
                    rotation: rotation,
                    detectionLevel: self.detectionLevel,
                    result: { [weak self] detected in self?.sendDetectionResult(detected) })
            }
        }
    }
    
    private func sendDetectionResult(_ result: DetectionResult) {
        guard self.started else { return }
        let param:[String : Any] = result.toMap()
        DispatchQueue.main.async { [weak self] in
            guard let eventSink = self?.eventSink else {
                return
            }
            eventSink(param)
        }
    }
    
}

extension MotionDetection: FlutterStreamHandler {
    
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


