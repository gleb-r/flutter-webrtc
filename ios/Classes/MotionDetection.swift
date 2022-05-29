//
//  MotionDetection.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

import Foundation
import WebRTC
import Flutter
import os.log

public class MotionDetection: NSObject, RTCVideoRenderer, FlutterStreamHandler {
    
    
    private lazy var pixelDetection = { PixelDetection() }()
    private var detectionLevel = 0
    private var frameSize: CGSize?
    private let eventChannel: FlutterEventChannel
    private var eventSink :FlutterEventSink?
    private var videoTrack: RTCVideoTrack?
    private var previosTime = CACurrentMediaTime()
    private var detectionInterval: Double = 0.2
    
    @objc public init(binaryMessager: FlutterBinaryMessenger) {
        eventChannel = FlutterEventChannel(name: "FlutterWebRTC/motionDetection", binaryMessenger: binaryMessager)
        super.init()
        eventChannel.setStreamHandler(self)
        
    }
    
    
    @objc public func start(videoTrack: RTCVideoTrack, detctionLevel: NSNumber, intervalMs: NSNumber, result: FlutterResult) {
        self.detectionLevel = detctionLevel.intValue
        self.detectionInterval = Double(intervalMs.intValue) / 1000
        result(true)
        videoTrack.add(self)
        self.videoTrack = videoTrack
        
    }
    
    @objc public func stop(result: FlutterResult) {
        guard let videoTrack = videoTrack else {
            result(false)
            return
        }
        videoTrack.remove(self)
        self.videoTrack = nil
        result(true)
    }
    
    @objc public func setDetectionLevel(level: Int) {
        self.detectionLevel = level
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
                self.pixelDetection.detect(buffer: buffer,
                                           rotation: rotation,
                                           detectionLevel: self.detectionLevel ) { [weak self] detectionResult in
                    self?.sendDetectionResult(detectionResult) }
            }
            
        }
    }
    
    private func sendDetectionResult(_ result: DetectionResult) {
        let param:[String : Any] = result.toMap()
        DispatchQueue.main.async { [weak self] in
            guard let eventSink = self?.eventSink else {
                return
            }
            eventSink(param)
        }
    }

    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}


