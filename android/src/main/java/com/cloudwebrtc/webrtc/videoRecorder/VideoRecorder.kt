package com.cloudwebrtc.webrtc.videoRecorder

import android.content.ContentValues
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import com.cloudwebrtc.webrtc.detection.DetectionResult
import com.cloudwebrtc.webrtc.detection.MotionDetection
import com.cloudwebrtc.webrtc.record.*
import com.cloudwebrtc.webrtc.utils.AnyThreadResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.webrtc.VideoTrack
import org.webrtc.audio.JavaAudioDeviceModule
import java.io.File
import java.lang.Exception

class VideoRecorder(
    binaryMessenger: BinaryMessenger,
    private val motionDetection: MotionDetection,
    private val audioDeviceModule: JavaAudioDeviceModule,
    private val applicationContext: Context
) : EventChannel.StreamHandler, MotionDetection.Listener, FirstFrameListener {

    private val eventChannel = EventChannel(
        binaryMessenger,
        "FlutterWebRTC/detectionOnVideo"
    )
    private var eventSink: EventChannel.EventSink? = null
    private var firstFrameTime: Long? = null
    private var isStarted = false
    private var mediaRecorder: MediaRecorderImpl? = null
    private var imageFile: File? = null
    private val inputInterceptor by lazy {
        AudioSamplesInterceptor()
    }
    private var isImageSaved = false
    private var frameRotation = 0

    private val outputInterceptor by lazy {
        OutputAudioSamplesInterceptor(audioDeviceModule)
    }

    init {
        eventChannel.setStreamHandler(this)
    }

    fun startRecording(
        videoPath: String,
        imagePath: String,
        videoTrack: VideoTrack,
        audioChannel: AudioChannel?,
        flutterResult: AnyThreadResult
    ) {
        if (isStarted) {
            flutterResult.success(false)
            return
        }
        isStarted = true
        isImageSaved = false
        val interceptor = audioChannel?.let {
            if (it == AudioChannel.INPUT) inputInterceptor else outputInterceptor
        }
        val videoFile = File(videoPath)
        val imageFile = File(imagePath)
        val callback = object : MethodChannel.Result {
            override fun success(result: Any?) {
                println("Frame image saved")
                isImageSaved = true
                this@VideoRecorder.imageFile = imageFile
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                flutterResult.error(errorCode, errorMessage, errorDetails)
            }

            override fun notImplemented() {}
        }
        FrameCapturer(videoTrack, imageFile, callback)
        mediaRecorder = MediaRecorderImpl(1, videoTrack, interceptor, this)
        mediaRecorder?.startRecording(videoFile)
        motionDetection.addListener(this)
        flutterResult.success(true)
    }

    fun stopRecording(flutterResult: AnyThreadResult) {
        val firstFrameTime = this.firstFrameTime
        if (!isStarted || firstFrameTime == null) {
            flutterResult.error(
                "stopRecording error",
                "recording is not started",
                null
            )
            return
        }
        val mediaRecorder = this.mediaRecorder ?: return
        motionDetection.removeListener()
        try {
            mediaRecorder.stopRecording()
        } catch (err: Exception) {
            flutterResult.error(
                "media recorder stop error",
                err.message,
                null
            )
            isStarted = false
            return
        }
        val duration = System.currentTimeMillis() - firstFrameTime
        val videoFile = mediaRecorder.recordFile
        if (videoFile != null) {
            val values = ContentValues(3)
            values.put(MediaStore.Video.Media.TITLE, videoFile.name)
            values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            values.put(MediaStore.Video.Media.DATA, videoFile.absolutePath)
            applicationContext.contentResolver.insert(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                values
            )
        } else {
            isStarted = false
            flutterResult.error("MediaRecorder file err", "File is null", null)
            return
        }
        val imagePath = imageFile?.path
        if (!isImageSaved || imagePath == null) {
            isStarted = false
            flutterResult.error("Recorder err", "Image is not saved", null)
            return
        }
        val recResult = RecordingResult(
            videoPath = videoFile.path,
            imagePath = imagePath,
            durationMs = duration,
            frameIntervalMs = motionDetection.frameIntervalMs,
            rotationDegree = frameRotation
        )
        flutterResult.success(recResult.toMap())
        this.isStarted = false
        this.mediaRecorder = null
        this.firstFrameTime = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    override fun onDetect(detection: DetectionResult) {
        if (detection.detectedList.isEmpty()) return
        firstFrameTime?.let { time ->
            val frameIndex = (System.currentTimeMillis() - time) / 300
            val frame = DetectionWithIndex(detection, frameIndex.toInt())
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(frame.toMap())
            }
        }
    }

    override fun onFirstFrame(frameRotation: Int) {
        println("On first frame called, rotation: $frameRotation")
        firstFrameTime = System.currentTimeMillis()
        this.frameRotation = frameRotation
    }
}
