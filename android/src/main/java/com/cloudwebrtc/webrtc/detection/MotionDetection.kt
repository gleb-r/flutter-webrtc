package com.cloudwebrtc.webrtc.detection

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

import java.nio.ByteBuffer
import kotlin.concurrent.thread

class MotionDetection(binaryMessenger: BinaryMessenger) : EventChannel.StreamHandler {
    private val pixelDetection by lazy { PixelDetection() }
    private val eventChannel = EventChannel(binaryMessenger, "FlutterWebRTC/motionDetection")
    private var eventSink: EventChannel.EventSink? = null
    private var detectionLevel = 2
    private var intervalMs = 300
    private var listener: Listener? = null
    private var isActive = false

    init {
        eventChannel.setStreamHandler(this)
    }

    fun requestMotionDetection(request: DetectionRequest) {
        detectionLevel = request.level
        if (request.enabled == isActive) {
            return
        }
        isActive = request.enabled
    }

    fun addListener(listener: Listener) {
        this.listener = listener
    }

    fun removeListener() {
        this.listener = null
    }

    fun processFrame(buffer: ByteBuffer, width: Int, height: Int, strideY: Int, rotation: Int) {
        thread {
            pixelDetection.detect(
                buffer = buffer,
                width = width,
                height = height,
                rotation = rotation,
                strideY = strideY,
                detectionLevel = detectionLevel
            ) { result ->
                sendDetection(result)
                listener?.onDetect(result)
            }
        }
    }

    private fun sendDetection(detected: DetectionFrame) {
        if (!isActive) return
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

    fun dispose() {
        if (isActive) {
            isActive = false
        }
        eventSink = null
        eventChannel.setStreamHandler(null)
    }

    interface Listener {
        fun onDetect(detection: DetectionFrame)
    }
}