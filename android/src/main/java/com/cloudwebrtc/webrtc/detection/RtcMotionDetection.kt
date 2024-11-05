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
    private var intervalMs = 300
    private var prevDetection = 0L

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
        get() = intervalMs.toLong()

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
        if (System.currentTimeMillis() - prevDetection < intervalMs) {
            return
        }
        prevDetection = System.currentTimeMillis()
        videoFrame.retain()
        val i420Buffer = videoFrame.buffer.toI420() ?: return
        val rotation = videoFrame.rotation
        videoFrame.release()
        motionDetection.processFrame(
            i420Buffer.dataY,
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
