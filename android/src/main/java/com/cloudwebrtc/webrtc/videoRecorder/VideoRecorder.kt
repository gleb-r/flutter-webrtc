package com.cloudwebrtc.webrtc.videoRecorder

import android.content.ContentValues
import android.content.Context
import android.provider.MediaStore
import android.util.Log
import com.cloudwebrtc.webrtc.detection.DetectionResult
import com.cloudwebrtc.webrtc.detection.MotionDetection
import com.cloudwebrtc.webrtc.record.AudioSamplesInterceptor
import com.cloudwebrtc.webrtc.record.FirstFrameListener
import com.cloudwebrtc.webrtc.record.FrameCapturer
import com.cloudwebrtc.webrtc.record.VideoFileRenderer
import com.cloudwebrtc.webrtc.utils.EglUtils
import io.flutter.plugin.common.MethodChannel
import org.webrtc.VideoTrack
import java.io.File
import kotlin.random.Random

class VideoRecorder(
    private val videoPath: String,
    private val imagePath: String,
    private val videoTrack: VideoTrack,
    private val audioInterceptor: AudioSamplesInterceptor?,
    private val directAudio: Boolean,
    private val withAudio: Boolean,
    private val motionDetection: MotionDetection,
    private val applicationContext: Context,
    private val onDetection: (DetectionWithIndex) -> Unit

) : FirstFrameListener, MotionDetection.Listener {
    private var imageSaved = false
    private val imageFile by lazy { File(imagePath) }
    private val videoFile by lazy { File(videoPath) }
    private var firstFrameTime: Long? = null
    private var frameRotation = 0
    private val id by lazy { Random(10000).nextInt() }

    private val videoFileRenderer by lazy {
        VideoFileRenderer(
            videoFile.absolutePath,
            EglUtils.getRootEglBaseContext(),
            withAudio,
            directAudio,
            this
        )
    }

    fun start() {
        videoFile.parentFile?.mkdirs()
        FrameCapturer(videoTrack, imageFile, imageSaveCallback)
        videoTrack.addSink(videoFileRenderer)
        audioInterceptor?.attachCallback(id, videoFileRenderer)
        motionDetection.addListener(this)
    }

    fun stop(): RecordingResult {
        motionDetection.removeListener()
        audioInterceptor?.detachCallback(id)
        videoTrack.removeSink(videoFileRenderer)
        videoFileRenderer.release()
        val firstFrame = this.firstFrameTime
            ?: throw Exception("First frame not saved")
        if (!imageSaved) {
            throw Exception("Image not saved")
        }
        val duration = System.currentTimeMillis() - firstFrame
        val values = ContentValues(3)
        values.put(MediaStore.Video.Media.TITLE, videoFile.name)
        values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
        values.put(MediaStore.Video.Media.DATA, videoFile.absolutePath)
        applicationContext.contentResolver.insert(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            values
        )
        return RecordingResult(
            videoPath = videoPath,
            imagePath = imagePath,
            durationMs = duration,
            frameIntervalMs = motionDetection.frameIntervalMs,
            rotationDegree = frameRotation
        )
    }


    private val imageSaveCallback = object : MethodChannel.Result {
        override fun success(result: Any?) {
            imageSaved = true
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            Log.e("VideoRecorder", "$errorCode, $errorMessage")
            // TODO: error through event chennel
//            flutterResult.error(errorCode, errorMessage, errorDetails)
        }

        override fun notImplemented() {}
    }

    override fun onFirstFrame(frameRotation: Int) {
        println("On first frame called, rotation: $frameRotation")
        firstFrameTime = System.currentTimeMillis()
        this.frameRotation = frameRotation
    }

    override fun onDetect(detection: DetectionResult) {
        if (detection.detectedList.isEmpty()) return
        firstFrameTime?.let { time ->
            val frameIndex = (System.currentTimeMillis() - time) / motionDetection.frameIntervalMs
            val frame = DetectionWithIndex(detection, frameIndex.toInt())
            onDetection(frame)
        }
    }

}