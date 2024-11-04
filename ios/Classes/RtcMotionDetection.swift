import Foundation
import WebRTC
import Flutter

public class RtcMotionDetection: NSObject, RTCVideoRenderer {
    private let motionDetection: MotionDetection
    private var videoTrack: RTCVideoTrack?
    private let log = Log(subsystem: "RtcMotionDetection", category: "")
    private var active = false

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
        motionDetection.frameIntervalMs
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

    public func setSize(_ size: CGSize) {
        // Optionally implement if needed
    }

    public func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else {
            return
        }
        let buffer = frame.buffer.toI420()
        let sampleBuffer = convertToCMSampleBuffer(buffer: buffer)
        motionDetection.processFrame(sampleBuffer)
    }

    private func convertToCMSampleBuffer(buffer: RTCI420BufferProtocol) -> CMSampleBuffer {
        // Placeholder function to convert RTCI420BufferProtocol to CMSampleBuffer
        // You need to implement this conversion or adjust the motionDetection to accept buffer directly
        fatalError("Conversion to CMSampleBuffer not implemented")
    }
}
