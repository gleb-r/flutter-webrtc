package com.cloudwebrtc.webrtc.detection

import android.graphics.Rect
import android.graphics.RectF
import android.util.Log
import com.cloudwebrtc.webrtc.utils.ConstraintsMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.webrtc.NetworkMonitor.init
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.VideoTrack

class MotionDetection(binaryMessenger: BinaryMessenger) : VideoSink, EventChannel.StreamHandler {
    private var videoTrack: VideoTrack? = null
    private var pixelDetection: PixelDetection? = null
    private val eventChannel = EventChannel(binaryMessenger, "FlutterWebRTC/motionDetection")
    private var eventSink: EventChannel.EventSink? = null
    private var prevDetection = 0L

    init {
        eventChannel.setStreamHandler(this)
    }

    fun starDetection(videoTrack: VideoTrack, detectionLevel: Int) {
        this.videoTrack = videoTrack
        this.pixelDetection = PixelDetection(detectionLevel)
        videoTrack.addSink(this)
        Log.d("TAG", "Motion detection started")
    }

    fun stopDetection() {
        this.pixelDetection = null
        videoTrack?.removeSink(this)
        videoTrack = null
        Log.d("TAG", "Motion detection stopped")

    }


    override fun onFrame(videoFrame: VideoFrame) {
        if (System.currentTimeMillis() - prevDetection < 200) {
            return
        }
        prevDetection = System.currentTimeMillis()
        videoFrame.retain()
        val i420Buffer = videoFrame.buffer.toI420() ?: return
        val rotation = videoFrame.rotation
        videoFrame.release()
        pixelDetection?.let {
            it.detect(i420Buffer, rotation) { result -> sendDetection(result) }
        }

    }

    private fun sendDetection(detected: List<Pair<RectF, Int>>) {
        val params = hashMapOf(
            "detected" to detected.isNotEmpty(),
            "rect" to detected.map { it.toMap() })
        eventSink?.success(params)
    }


    private fun RectF.toMap(): HashMap<String, Double> =
        hashMapOf(
            "l" to left.toDouble(),
            "t" to top.toDouble(),
            "r" to right.toDouble(),
            "b" to bottom.toDouble()
        )

    private fun Pair<RectF, Int>.toMap(): HashMap<String, Any> =
        hashMapOf(
            "l" to first.left.toDouble(),
            "t" to first.top.toDouble(),
            "r" to first.right.toDouble(),
            "b" to first.bottom.toDouble(),
            "c" to second
        )


    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    interface Callback {
        fun detect(squares: List<Rect>)
    }
}


