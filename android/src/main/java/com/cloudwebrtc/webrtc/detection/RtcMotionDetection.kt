package com.cloudwebrtc.webrtc.detection

import org.webrtc.VideoFrame
import java.nio.ByteBuffer
import io.flutter.plugin.common.BinaryMessenger
import android.util.Log
import org.webrtc.VideoSink
import org.webrtc.VideoTrack

class RtcMotionDetection(binaryMessenger: BinaryMessenger) : VideoSink {
    private val motionDetection = MotionDetection(binaryMessenger)
    private var videoTrack: VideoTrack? = null

    fun setVideoTrack(videoTrack: VideoTrack) {
        if (this.videoTrack != null) {
            return
        }
        this.videoTrack = videoTrack
        if (isActive) {
            startDetection(videoTrack)
        }
    }

    fun addListener(listener: MotionDetection.Listener) {
        this.motionDetection.addListener(listener)
    }

    fun removeListener() {
        this.motionDetection.removeListener()
    }

    fun removeVideoTrack(trackId: String) {
        if (videoTrack?.id() != trackId) {
            return
        }
        stopDetection()
        videoTrack = null
    }

    val frameIntervalMs: Long
        get() = this.motionDetection.frameIntervalMs

    private var isActive = false

    fun requestMotionDetection(request: DetectionRequest) {
        motionDetection.requestMotionDetection(request)
        if (request.enabled == isActive) {
            return
        }
        isActive = request.enabled
        if (isActive) {
            videoTrack?.let { track ->
                startDetection(track)
            } ?: run {
                Log.d("Motion detection", "VideoTrack is null")
            }
        } else {
            stopDetection()
        }
    }

    private fun startDetection(videoTrack: VideoTrack) {
        videoTrack.addSink(this)
        Log.d("Motion detection", "Motion detection started")
    }

    private fun stopDetection() {
        videoTrack?.removeSink(this)
        motionDetection.dispose()
        Log.d("TAG", "Motion detection stopped")
    }

    override fun onFrame(videoFrame: VideoFrame) {
        val i420Buffer = videoFrame.buffer.toI420() ?: return
        val yPlane = i420Buffer.dataY
        val uPlane = i420Buffer.dataU
        val vPlane = i420Buffer.dataV

        val ySize = i420Buffer.height * i420Buffer.strideY
        val uSize = (i420Buffer.height / 2) * i420Buffer.strideU
        val vSize = (i420Buffer.height / 2) * i420Buffer.strideV

        val byteBuffer = ByteBuffer.allocateDirect(ySize + uSize + vSize)
        byteBuffer.put(yPlane)
        byteBuffer.put(uPlane)
        byteBuffer.put(vPlane)
        motionDetection.processFrame(
            byteBuffer,
            i420Buffer.width,
            i420Buffer.height,
            i420Buffer.strideY,
            videoFrame.rotation)
    }

    fun dispose() {
        if (isActive) {
            stopDetection()
        }
        videoTrack = null
        motionDetection.dispose()
    }
}
