package com.cloudwebrtc.webrtc.videoRecorder

import android.content.ContentValues
import android.content.Context
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import com.cloudwebrtc.webrtc.detection.DetectionResult
import com.cloudwebrtc.webrtc.detection.MotionDetection
import com.cloudwebrtc.webrtc.record.AudioSamplesInterceptor
import com.cloudwebrtc.webrtc.record.FirstFrameListener
import com.cloudwebrtc.webrtc.record.VideoFileRenderer
import com.cloudwebrtc.webrtc.utils.EglUtils
import io.flutter.plugin.common.MethodChannel
import io.flutter.util.PathUtils.getFilesDir
import org.webrtc.VideoTrack
import java.io.File
import java.util.UUID
import kotlin.random.Random

public class VideoRecorder(
    private val videoTrack: VideoTrack,
    private val dirPath: String,
    private val audioInterceptor: AudioSamplesInterceptor?,
    private val directAudio: Boolean,
    private val withAudio: Boolean,
    private val motionDetection: MotionDetection,
    private val applicationContext: Context,
    private val onStateChange: (RecordState) -> Unit,

    ) : FirstFrameListener, MotionDetection.Listener {
    private val recordId by lazy { UUID.randomUUID().toString() }

    private val videoFile: File by lazy {
        File("$dirPath/$recordId.mp4")
    }
    private var firstFrameTime: Long? = null
    private var frameRotation = 0
    private val id by lazy { Random(10000).nextInt() }

    private var detectionData: DetectionData? = null

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
        onStateChange(RecordState.starting)
        videoFile.parentFile?.mkdirs()
        Log.d("TAG", "Start recording, file: ${videoFile.absolutePath}")
        videoTrack.addSink(videoFileRenderer)
        audioInterceptor?.attachCallback(id, videoFileRenderer)
        motionDetection.addListener(this)
    }

    fun stop(): RecordingResult {
        onStateChange(RecordState.stop)
        motionDetection.removeListener()
        audioInterceptor?.detachCallback(id)
        videoTrack.removeSink(videoFileRenderer)
        // TODO: try catch
        videoFileRenderer.release()
        val firstFrame = this.firstFrameTime
            ?: throw Exception("First frame not saved")
        val duration = System.currentTimeMillis() - firstFrame
        Log.d("TAG", "Stop recording without content resolver")
        val values = ContentValues(3)
        onStateChange(RecordState.idle)
//        values.put(MediaStore.Video.Media.TITLE, videoFile.name)
//        values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
//        values.put(MediaStore.Video.Media.DATA, videoFile.absolutePath)
//        applicationContext.contentResolver.insert(
//            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
//            values
//        )
        detectionData?.duration = duration
        return RecordingResult(
            recordId = recordId,
            videoPath = videoFile.absolutePath,
            durationMs = duration,
            rotationDegree = frameRotation,
            detection = detectionData?.toMap()
        )
    }

    override fun onFirstFrame(frameRotation: Int) {
        println("On first frame called, rotation: $frameRotation")
        firstFrameTime = System.currentTimeMillis()
        this.frameRotation = frameRotation
        onStateChange(RecordState.recording)
    }

    override fun onDetect(detection: DetectionResult) {
        if (detection.detectedList.isEmpty()) return
        firstFrameTime?.let { time ->
            val frameIndex =
                (System.currentTimeMillis() - time) / motionDetection.frameIntervalMs
            val frameIndexStr = frameIndex.toString()
            if (detectionData == null) {
                detectionData = DetectionData(
                    detection,
                    frameIndexStr,
                    frameInterval = motionDetection.frameIntervalMs.toInt()
                )
            } else {
                detectionData?.addFrame(frameIndexStr, detection)
            }

        }
    }
}