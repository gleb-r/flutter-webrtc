package com.cloudwebrtc.webrtc.detection

import android.graphics.RectF
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.VideoTrack
import kotlin.concurrent.thread

class MotionDetection(binaryMessenger: BinaryMessenger) : VideoSink, EventChannel.StreamHandler {
    private var videoTrack: VideoTrack? = null
    private val pixelDetection by lazy { PixelDetection() }
    private val eventChannel = EventChannel(binaryMessenger, "FlutterWebRTC/motionDetection")
    private var eventSink: EventChannel.EventSink? = null
    private var prevDetection = 0L
    private var detectionLevel = 5
    private var intervalMs = 200

    init {
        eventChannel.setStreamHandler(this)
    }

    fun starDetection(videoTrack: VideoTrack, detectionLevel: Int = 5, intervalMs: Int = 200) {
        this.videoTrack = videoTrack
        this.detectionLevel = detectionLevel
        this.intervalMs = intervalMs
        videoTrack.addSink(this)
        Log.d("TAG", "Motion detection started")
    }

    fun stopDetection() {
        videoTrack?.removeSink(this)
        videoTrack = null
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
        thread {
            pixelDetection.detect(
                buffer = i420Buffer,
                rotation = rotation,
                detectionLevel = detectionLevel
            ) { result -> sendDetection(result) }
        }
    }

    private fun sendDetection(detected: DetectionResult) {
        val params = detected.toMap()
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(params)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}


