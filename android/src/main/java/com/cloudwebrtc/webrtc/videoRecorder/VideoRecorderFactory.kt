package com.cloudwebrtc.webrtc.videoRecorder

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.cloudwebrtc.webrtc.detection.MotionDetection
import com.cloudwebrtc.webrtc.record.OutputAudioSamplesInterceptor
import com.cloudwebrtc.webrtc.utils.AnyThreadResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.webrtc.VideoTrack
import org.webrtc.audio.JavaAudioDeviceModule

class VideoRecorderFactory(
    binaryMessenger: BinaryMessenger,
    private val motionDetection: MotionDetection,
    private val audioDeviceModule: JavaAudioDeviceModule,
    private val applicationContext: Context
) : EventChannel.StreamHandler {

    private val eventChannel = EventChannel(
        binaryMessenger,
        "FlutterWebRTC/detectionOnVideo"
    )
    private var eventSink: EventChannel.EventSink? = null
    private var videoRecorder: VideoRecorder? = null

    private val outputInterceptor by lazy {
        OutputAudioSamplesInterceptor(audioDeviceModule)
    }

    init {
        eventChannel.setStreamHandler(this)
    }

    fun startRecording(
        videoTrack: VideoTrack,
        dirPath: String,
        withAudio: Boolean,
        isDirect: Boolean,
        flutterResult: AnyThreadResult
    ) {
        if (videoRecorder != null) {
            flutterResult.success(false)
            return
        }

        val interceptor = if (withAudio && !isDirect) outputInterceptor else null

        CoroutineScope(Dispatchers.IO).launch {
            val videoRecorder = VideoRecorder(
                videoTrack = videoTrack,
                dirPath = dirPath,
                audioInterceptor = interceptor,
                withAudio = withAudio,
                directAudio = isDirect,
                motionDetection = motionDetection,
                applicationContext = applicationContext,
                onDetection = { sendDetection(it) }
            )
            videoRecorder.start()
            this@VideoRecorderFactory.videoRecorder = videoRecorder
            launch(Dispatchers.Main) {
                flutterResult.success(true)
            }
        }
    }

    fun stopRecording(flutterResult: AnyThreadResult) {
        val videoRecorder = this.videoRecorder
        if (videoRecorder == null) {
            flutterResult.error(
                "stopRecording error",
                "recording is not started",
                null
            )
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val result = videoRecorder.stop()
                launch(Dispatchers.Main) {
                    flutterResult.success(result.toMap())
                }
            } catch (err: Exception) {
                launch(Dispatchers.Main) {
                    flutterResult.error(
                        "media recorder stop error",
                        err.message,
                        null
                    )
                }
            } finally {
                this@VideoRecorderFactory.videoRecorder = null
            }
        }
    }

    private fun sendDetection(detection: DetectionWithIndex) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(detection.toMap())
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}
