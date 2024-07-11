package com.cloudwebrtc.webrtc.videoRecorder

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
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
        //TODO: Rename channel
        "FlutterWebRTC/detectionOnVideo"
    )
    private var eventSink: EventChannel.EventSink? = null
    private var videoRecorder: VideoRecorder? = null
    private var state = RecordState.idle

    private val outputInterceptor by lazy {
        OutputAudioSamplesInterceptor(audioDeviceModule)
    }

    init {
        eventChannel.setStreamHandler(this)
    }

    fun startRecording(
        videoTrack: VideoTrack,
        recordId: String,
        path: String,
        withAudio: Boolean,
        isDirect: Boolean,
        flutterResult: AnyThreadResult
    ) {
        if (videoRecorder != null) {
            flutterResult.success(false)
            return
        }
        if (state != RecordState.idle) {
            Log.e("VideoRecorderFactory", "startRecording: state: $state")
            flutterResult.success(false)
            return
        }

        val interceptor =
            if (withAudio && !isDirect) outputInterceptor else null
        state = RecordState.starting
        CoroutineScope(Dispatchers.IO).launch {
            val videoRecorder = VideoRecorder(
                videoTrack = videoTrack,
                recordId = recordId,
                path = path,
                audioInterceptor = interceptor,
                withAudio = withAudio,
                directAudio = isDirect,
                motionDetection = motionDetection,
                applicationContext = applicationContext,
                onStateChange = { newState ->
                    state = newState
                    sendEvent(
                        RecordEvent(
                            RecordEventType.fromState(state),
                            null
                        )
                    )
                }
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
        // TODO: stop when starting state
        if (state != RecordState.recording) {
            Log.e("VideoRecorderFactory", "stopRecording: state: $state")
            sendErrorEvent(
                RecordError(
                    "stopRecording error",
                    "recording is not started",
                )
            )
            return
        }
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val result = videoRecorder.stop()
                sendEvent(
                    RecordEvent(
                        RecordEventType.result,
                        result.toMap()
                    )
                )
                launch(Dispatchers.Main) {
                    flutterResult.success(true)
                }
            } catch (err: Exception) {
                sendErrorEvent(
                    RecordError(
                        "media recorder stop error",
                        err.message
                    )
                )
            } finally {
                this@VideoRecorderFactory.videoRecorder = null
            }
        }
    }

    private fun sendErrorEvent(error: RecordError) {
        sendEvent(
            RecordEvent(
                RecordEventType.error,
                error.toMap()
            )
        )
    }

    private fun sendEvent(recordEvent: RecordEvent) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(recordEvent.toMap())
            Log.i("RecodingFactory", "sendEvent: $recordEvent")
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}
