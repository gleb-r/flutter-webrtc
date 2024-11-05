//
//  MotionDetection.swift
//  flutter_webrtc
//
//  Created by MacBook 16 on 28.05.2022.
//

import Foundation
import Flutter
import CoreMedia
import CoreVideo
import AVFoundation

public class MotionDetection: NSObject {

    private lazy var pixelDetection = { PixelDetection() }()
    private var detectionLevel = 0
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
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

    @objc public func setDetection(request: DetectionRequest) {
        log.d("setDetection \(request.enabled)")
        self.detectionLevel = request.level
        guard self.active != request.enabled else { return }
        self.active = request.enabled
    }

    @objc public func stop() {
        self.pixelDetection.resetPrevious()
        log.d("stopped")
    }

    @objc public func dispose() {
        if active {
            stop()
        }
        eventChannel.setStreamHandler(nil)
        eventSink = nil
        log.d("disposed")
    }

    func addListener(_ listener: MotionDetectionListener) {
        self.listener = listener
    }

    func removeListener() {
        self.listener = nil
    }

    func processFrame(buffer: UnsafePointer<UInt8>,
                      rotation: Int,
                      width: Int,
                      height: Int,
                      strideY: Int) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.pixelDetection.detect(
                buffer: buffer,
                rotation: rotation,
                detectionLevel: self.detectionLevel,
                width: width,
                height: height,
                strideY: strideY,
                result: { [weak self] detected in
                    self?.sendDetectionResult(detected)
                    if !detected.detectedList.isEmpty {
                        self?.listener?.onDetected(result: detected)
                    }
                }
            )
        }
    }

    private func sendDetectionResult(_ result: DetectionFrame) {
        guard self.active else { return }
        let param: [String: Any] = result.toMap()
        DispatchQueue.main.async { [weak self] in
            guard let eventSink = self?.eventSink else {
                return
            }
            eventSink(param)
        }
    }
}

extension MotionDetection: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
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
