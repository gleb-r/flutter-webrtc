//
//  MotionDetection.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

import Foundation
import WebRTC
import Flutter

public class MotionDetection: NSObject, RTCVideoRenderer {
    
    private lazy var pixelDetection = { PixelDetection() }()
    private var detectionLevel = 0
    private var frameSize: CGSize?
    private let eventChannel: FlutterEventChannel
    private var eventSink :FlutterEventSink?
    private var videoTrack: RTCVideoTrack?
    private var previosTime = CACurrentMediaTime()
    private var detectionInterval: Double = 0.3

    private var listener: MotionDetectionListener?
    private let log = Log(subsystem: "MotionDetection", category: "")
    
    private var active = false
    @objc public init(binaryMessenger: FlutterBinaryMessenger) {
        eventChannel = FlutterEventChannel(
            name: "FlutterWebRTC/motionDetection",
            binaryMessenger: binaryMessenger)
        super.init()
        eventChannel.setStreamHandler(self)
    }
    
    var frameIntervalMs: Int {
       Int(detectionInterval * 1000)
    }
    
    @objc public func setVideoTrack(videoTrack: RTCVideoTrack) {
        log.d("setVideoTrack")
        guard self.videoTrack == nil else { return }
        self.videoTrack = videoTrack
        log.d("setVideoTrack \(active)")
        if active {
            start(videoTrack: videoTrack)
        }
    }
    
    @objc public func removeVideoTrack(trackId:String) {
        guard let videoTrack = self.videoTrack, videoTrack.trackId == trackId else { return }
        stop()
        self.videoTrack = nil
        log.d("removedVideoTrack")
    }
    
    
    @objc public func setDetection(request: DetectionRequest
    ) {
        log.d("setDetection \(request.enabled)")
        self.detectionLevel = request.level
        guard self.active != request.enabled else { return }
        self.active = request.enabled
        if active {
            guard let videoTrack = self.videoTrack else { return }
            start(videoTrack: videoTrack)
        } else {
            stop()
        }
    }
    
    
    private func start(videoTrack: RTCVideoTrack) {
        videoTrack.add(self)
        log.d("started")
    }
    
    @objc public func stop() {
        videoTrack?.remove(self)
        self.pixelDetection.resetPrevious()
        log.d("stopped")
    }

    @objc public func dispose() {
        if active {
            stop()
        }
        eventChannel.setStreamHandler(nil)
        eventSink = nil
        videoTrack = nil
        log.d("disposed")
    }

    
    func addListener(listener: MotionDetectionListener){
        self.listener = listener
    }
    
    func removeLister() {
        self.listener = nil
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
                    result: { [weak self] detected in
                        self?.sendDetectionResult(detected)
                        if !detected.detectedList.isEmpty {
                            self?.listener?.onDetected(result: detected)
                        }
                    }
                )
            }
        }
    }
    
    private func sendDetectionResult(_ result: DetectionFrame) {
        guard self.active else { return }
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

protocol MotionDetectionListener {
    func onDetected(result: DetectionFrame)
}


