package com.cloudwebrtc.webrtc.videoRecorder

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.cloudwebrtc.webrtc.detection.MotionDetection
import com.cloudwebrtc.webrtc.utils.AnyThreadResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.webrtc.VideoTrack
import org.webrtc.audio.JavaAudioDeviceModule
import java.io.File

class VideoRecorderFactory(
    binaryMessenger: BinaryMessenger,
    val videoTrackId: String,
    private val motionDetection: MotionDetection?,
    private val audioDeviceModule: JavaAudioDeviceModule,
    private val applicationContext: Context
) : EventChannel.StreamHandler {

    private val eventChannel: EventChannel = EventChannel(
        binaryMessenger,
        "FlutterWebRTC/record_event/${videoTrackId}"
    )
    private var eventSink: EventChannel.EventSink? = null
    private var videoRecorder: AsyncFileRenderer? = null
    private val TAG = "VideoRecorderFactory"


    init {
        eventChannel.setStreamHandler(this)
    }

    fun startRecording(
        videoTrack: VideoTrack,
        recordId: String,
        path: String,
        withAudio: Boolean,
        isLocal: Boolean,
        flutterResult: AnyThreadResult,
    ) {
        if (videoRecorder != null) {
            Log.e(
                TAG,
                "Recording is already started"
            )
            eventSink?.error(
                "startRecording error",
                "recording is already started",
                null
            )
            flutterResult.success(false)
            return
        }
        videoRecorder = AsyncFileRenderer(
            path = getCorrectPath(path),
            recordId = recordId,
            audioDeviceModule = audioDeviceModule,
            videoTrack = videoTrack,
            isLocal = isLocal,
            isAudioEnabled = withAudio,
            motionDetection = motionDetection,
            listener = recorderListener
        )
        videoRecorder?.start()
        flutterResult.success(true)
    }

    private fun getCorrectPath(path: String): String {
        val videoFile = File(path)
        videoFile.parentFile?.mkdirs()
        return videoFile.absolutePath
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
        val result = videoRecorder.stop()
        this.videoRecorder = null
        if (result != null) {
            sendEvent(
                RecordEvent(
                    RecordEventType.result,
                    result.toMap()
                )
            )
            flutterResult.success(true)
        } else {
            // TODO: send error
        }
    }

    fun dispose() {
        videoRecorder?.stop()
        videoRecorder = null
    }

    // CRUTCH: for old android devices (api < 30)
    // if error occurs with audio recording, we recreate recorder without audio
    private fun recreateRecorderWithoutAudio() {
        val oldRecorder = this.videoRecorder ?: return
        val path = oldRecorder.path
        val recordId = oldRecorder.recordId
        val videoTrack = oldRecorder.videoTrack
        val isLocal = oldRecorder.isLocal
        oldRecorder.stop()
        // TODO: maybe delay needed
        File(path).delete()
        this.videoRecorder = null

        videoRecorder = AsyncFileRenderer(
            path = getCorrectPath(path),
            recordId = recordId,
            audioDeviceModule = audioDeviceModule,
            videoTrack = videoTrack,
            isLocal = isLocal,
            isAudioEnabled = false,
            motionDetection = motionDetection,
            listener = recorderListener
        )
        videoRecorder?.start()
    }

    private val recorderListener = object : AsyncFileRenderer.Callback {
        override fun onStateChange(state: RecordState) {
            sendEvent(
                RecordEvent(
                    RecordEventType.fromState(state),
                    null
                )
            )
        }

        override fun onError(e: Exception) {
            Log.e(TAG, "recorderListener onError: $e")
            if (e is AsyncFileRenderer.AudioRecordNoDataError) {
                recreateRecorderWithoutAudio()
            }
            sendErrorEvent(
                RecordError(
                    "recording error",
                    e.message ?: e.toString(),
                )
            )

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
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}
