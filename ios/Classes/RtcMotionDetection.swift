import Foundation
import WebRTC
import Flutter

public class RtcMotionDetection: NSObject, RTCVideoRenderer {
    private let motionDetection: MotionDetection
    private var videoTrack: RTCVideoTrack?
    private let log = Log(subsystem: "RtcMotionDetection", category: "")
    private var active = false
    private var previousTime = CACurrentMediaTime()
    private var detectionInterval: Double = 0.3

    @objc public init(binaryMessenger: FlutterBinaryMessenger) {
        self.motionDetection = MotionDetection(binaryMessenger: binaryMessenger)
        super.init()
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

    @objc public func removeVideoTrack(trackId: String) {
        guard let videoTrack = self.videoTrack, videoTrack.trackId == trackId else { return }
        stop()
        self.videoTrack = nil
        log.d("removedVideoTrack")
    }

    @objc public func setDetection(request: DetectionRequest) {
        log.d("setDetection \(request.enabled)")
        self.active = request.enabled
        motionDetection.setDetection(request: request)
        if active {
            guard let videoTrack = self.videoTrack else { return }
            start(videoTrack: videoTrack)
        } else {
            stop()
        }
    }

    var frameIntervalMs: Int {
        Int(detectionInterval * 1000)
    }

    private func start(videoTrack: RTCVideoTrack) {
        videoTrack.add(self)
        log.d("started")
    }

    @objc public func stop() {
        videoTrack?.remove(self)
        motionDetection.stop()
        log.d("stopped")
    }

    func addListener(listener: MotionDetectionListener){
        motionDetection.addListener(listener)
    }

    func removeListener() {
        motionDetection.removeListener()
    }

    @objc public func dispose() {
        if active {
            stop()
        }
        videoTrack = nil
        log.d("disposed")
    }

    public func setSize(_ size: CGSize) {}

    public func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else {
            return
        }
        let currentTime = CACurrentMediaTime()
        if (currentTime - previousTime > CFTimeInterval(detectionInterval)) {
            previousTime = currentTime
            let buffer = frame.buffer.toI420()
            let rotation = frame.rotation
            motionDetection.processFrame(
                buffer: buffer.dataY,
                rotation: rotation.rawValue,
                width: Int(frame.width),
                height: Int(frame.height),
                strideY: Int(buffer.strideY)
            )
        }
    }
}
