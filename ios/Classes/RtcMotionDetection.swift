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
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let width = Int(buffer.width)
        let height = Int(buffer.height)
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attributes as CFDictionary, &pixelBuffer)
        guard let pixelBufferUnwrapped = pixelBuffer else {
            fatalError("Failed to create pixel buffer")
        }
        CVPixelBufferLockBaseAddress(pixelBufferUnwrapped, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBufferUnwrapped, .readOnly) }

        // Copy Y plane
        let yBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBufferUnwrapped, 0)
        let yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBufferUnwrapped, 0)
        for y in 0..<height {
            memcpy(yBaseAddress?.advanced(by: y * yStride), buffer.dataY.advanced(by: y * Int(buffer.strideY)), width)
        }

        // Copy U and V planes
        // Copy U and V planes
        let uvBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBufferUnwrapped, 1)
        let uStride = Int(buffer.strideU)
        let vStride = Int(buffer.strideV)
        let uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBufferUnwrapped, 1)
        for y in 0..<height / 2 {
            for x in 0..<width / 2 {
                let uValue = buffer.dataU.advanced(by: y * uStride + x).pointee
                let vValue = buffer.dataV.advanced(by: y * vStride + x).pointee
                uvBaseAddress?.advanced(by: y * uvStride + x * 2).storeBytes(of: uValue, as: UInt8.self)
                uvBaseAddress?.advanced(by: y * uvStride + x * 2 + 1).storeBytes(of: vValue, as: UInt8.self)
            }
        }

        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: CMTime.zero, decodeTimeStamp: CMTime.invalid)
        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBufferUnwrapped, formatDescriptionOut: &formatDescription)
        guard let formatDesc = formatDescription else {
            fatalError("Failed to create format description")
        }
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBufferUnwrapped, formatDescription: formatDesc, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)

        guard let sampleBufferUnwrapped = sampleBuffer else {
            fatalError("Failed to create CMSampleBuffer")
        }

        return sampleBufferUnwrapped
    }
}
