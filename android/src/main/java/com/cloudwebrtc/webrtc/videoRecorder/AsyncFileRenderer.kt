package com.cloudwebrtc.webrtc.videoRecorder

import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMuxer
import com.cloudwebrtc.webrtc.detection.DetectionFrame
import com.cloudwebrtc.webrtc.detection.MotionDetection
import com.cloudwebrtc.webrtc.record.OutputAudioSamplesInterceptor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.webrtc.Logging
import org.webrtc.VideoTrack
import org.webrtc.audio.JavaAudioDeviceModule
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.random.Random


/**
 * Asynchronously renders video and audio tracks to a file.
 *
 * This class utilizes MediaMuxer to combine video and audio streams into a single output file.
 * It supports motion detection and can be configured for local or remote recording scenarios.
 *
 * @param path The path to the output file.
 * @param recordId A unique identifier for the recording.
 * @param listener A callback to receive state changes and errors.
 * @param isLocal Indicates whether the recording is local or remote.
 * @param isAudioEnabled Indicates whether audio recording is enabled.
 * @param videoTrack The video track to be rendered.
 * @param motionDetection An optional motion detection instance.
 * @param audioDeviceModule The audio device module for audio input.
 */
class AsyncFileRenderer(
    internal val path: String,
    val recordId: String,
    private val listener: Callback,
    internal val isLocal: Boolean,
    private val isAudioEnabled: Boolean,
    internal val videoTrack: VideoTrack,
    private val motionDetection: MotionDetection?,
    private val audioDeviceModule: JavaAudioDeviceModule,
) : MotionDetection.Listener {
    private val TAG = "AsyncFileRenderer"

    val id by lazy { Random(10000).nextInt() }
    private var detectionData: DetectionData? = null

    private var outputInterceptor: OutputAudioSamplesInterceptor? = null

    @Volatile
    private var audioTrackIndex = -1

    @Volatile
    private var videoTrackIndex = -1
    private val mediaMuxer =
        MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

    private var isMuxerStarted = AtomicBoolean(false)

    private val videoEncoder by lazy {
        VideoAsyncEncoder(
            renderScope,
            videoCallback
        )
    }

    private var audioEncoder: AudioAsyncEncoder? = null
    private val renderScope by lazy { CoroutineScope(Dispatchers.IO + SupervisorJob()) }

    private var startTimeNs = 0L

    // used to avoid recording audio samples in incorrect order
    private var previousAudioTimeUs = 0L

    private var framesSkipped = 0
    private var audioSamplesSkipped = 0

    private var currentState = RecordState.idle
        set(value) {
            if (field == value) {
                return
            }
            field = value
            listener.onStateChange(value)
            Logging.d(TAG, "==== State changed to $value")
        }

    fun start() {
        if (isAudioEnabled) {
            val audioEncoder = AudioAsyncEncoder(
                isLocal,
                renderScope,
                audioCallback
            )
            if (isLocal) {
                audioEncoder.initializeLocal()
            } else {
                outputInterceptor =
                    OutputAudioSamplesInterceptor(audioDeviceModule)
                outputInterceptor?.attachCallback(id, audioEncoder)
            }
            this.audioEncoder = audioEncoder
        }
        videoTrack.addSink(videoEncoder)
        motionDetection?.addListener(this)
        currentState = RecordState.starting
    }

    private val startTimeMs: Long?
        get() {
            if (startTimeNs == 0L) return null
            return startTimeNs / 1_000_000
        }

    fun stop(): RecordingResult? {
        if (currentState == RecordState.disposing) {
            return null
        }
        currentState = RecordState.disposing
        videoTrack.removeSink(videoEncoder)
        outputInterceptor?.detachCallback(id)
        motionDetection?.removeListener()
        videoEncoder.dispose()
        audioEncoder?.dispose()
        if (isMuxerStarted.get()) {
            try {
                // TODO: it's recommended to add some delay before stop
                mediaMuxer.stop()
                mediaMuxer.release()
            } catch (e: IllegalStateException) {
                Logging.e(TAG, "Error stopping muxer", e)
                listener.onError(MuxerStopError())
                return null
            } catch (e: Exception) {
                Logging.e(TAG, "Error stopping muxer", e)
                listener.onError(e)
                return null
            } finally {
                currentState = RecordState.idle
                renderScope.cancel()
            }

        }
        Logging.d(
            TAG, "Media muxer Disposed , " +
                    "audio samples skipped: $audioSamplesSkipped, " +
                    "frames skipped: $framesSkipped"
        )
        val startTime = startTimeMs
        val frameRotation = videoEncoder.frameRotation
        if (startTime == null || frameRotation == null) {
            return null
        }
        val duration = System.currentTimeMillis() - startTime
        detectionData?.duration = duration
        return RecordingResult(
            recordId = recordId,
            videoPath = path,
            durationMs = duration,
            rotationDegree = frameRotation,
            detection = detectionData?.toMap()
        )
    }

    private fun startMuxer() {
        if (isMuxerStarted.get()) {
            listener.onError(MuxerAlreadyStartedError())
            return
        }
        if (videoTrackIndex != -1 && (audioTrackIndex != -1 || !isAudioEnabled)) {
            mediaMuxer.start()
            isMuxerStarted.set(true)
            startTimeNs = System.nanoTime()
            currentState = RecordState.recording
            writeKeyFrame()
        }
    }

    /// We should start writing with key frame,
    // otherwise mediaMuxer will skip other frames until key frame appears
    private fun writeKeyFrame() {
        val keyFrameData = keyFrameData ?: return
        val keyFrameBufferInfo = keyFrameBufferInfo ?: return
        keyFrameBufferInfo.presentationTimeUs = presentationTimeUs()
        mediaMuxer.writeSampleData(
            videoTrackIndex,
            keyFrameData,
            keyFrameBufferInfo
        )
        this.keyFrameData = null
        this.keyFrameBufferInfo = null
    }

    private var keyFrameData: ByteBuffer? = null
    private var keyFrameBufferInfo: MediaCodec.BufferInfo? = null

    private val videoCallback = object : VideoAsyncEncoder.Callback {
        override fun saveData(
            encodedData: ByteBuffer,
            bufferInfo: MediaCodec.BufferInfo
        ) {
            val isKeyFrame =
                bufferInfo.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME != 0
            if (!isMuxerStarted.get()) {
                if (isKeyFrame) {
                    keyFrameData = ByteBuffer.allocate(encodedData.remaining())
                    keyFrameData?.put(encodedData)
                    keyFrameBufferInfo = bufferInfo;
                }
                framesSkipped++
                return
            }
            bufferInfo.presentationTimeUs = presentationTimeUs()
            mediaMuxer.writeSampleData(
                videoTrackIndex,
                encodedData,
                bufferInfo
            )
            Logging.d(TAG, "==== Video data written to muxer")
        }

        override fun addTrack(mediaFormat: MediaFormat) {
            if (videoTrackIndex != -1) {
                listener.onError(VideoTrackAlreadySetError())
                return
            }
            Logging.d(
                TAG,
                "==== Video track added to muxer, format: $mediaFormat"
            )
            videoTrackIndex = mediaMuxer.addTrack(mediaFormat)
            startMuxer()
        }

        override fun onError(e: Exception) {
            listener.onError(e)
        }
    }

    private val audioCallback = object : AudioAsyncEncoder.Callback {
        override fun presentationTimeUs(): Long =
            this@AsyncFileRenderer.presentationTimeUs()

        override fun saveData(
            encodedData: ByteBuffer,
            bufferInfo: MediaCodec.BufferInfo
        ) {
            if (!isMuxerStarted.get()) {
                audioSamplesSkipped++
                return
            }
            if (audioTrackIndex == -1) {
                listener.onError(AudioTrackNotSetError())
                return
            }
            if (bufferInfo.presentationTimeUs == 0L) {
                audioSamplesSkipped++
                return
            }
            if (bufferInfo.presentationTimeUs < previousAudioTimeUs) {
                listener.onError(OldAudioSampleError())
                return
            }
            previousAudioTimeUs = bufferInfo.presentationTimeUs
            try {
                mediaMuxer.writeSampleData(
                    audioTrackIndex,
                    encodedData,
                    bufferInfo
                )
                Logging.d(TAG, "==== Audio data written to muxer")
            } catch (e: Exception) {
                listener.onError(ErrorWritingAudioData(info = e.toString()))
            }
        }

        override fun addTrack(mediaFormat: MediaFormat) {
            if (audioTrackIndex != -1) {
                listener.onError(AudioTrackAlreadySetError())
                return
            }
            Logging.d(
                TAG,
                "==== Audio track added to muxer, format: $mediaFormat"
            )
            audioTrackIndex = mediaMuxer.addTrack(mediaFormat)
            startMuxer()
        }

        override fun onError(e: Exception) {
            listener.onError(e)
        }
    }


    override fun onDetect(detection: DetectionFrame) {
        // TODO: detection data could be directly written to muxer
        //  https://developer.android.com/reference/android/media/MediaMuxer#metadata-track
        val motionDetection =
            this.motionDetection ?: return
        val firstFrameTime = startTimeMs ?: return
        if (detection.detectedList.isEmpty()) return
        val frameIndex =
            (System.currentTimeMillis() - firstFrameTime) / motionDetection.frameIntervalMs
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

    private fun presentationTimeUs(): Long {
        if (startTimeNs == 0L) {
            return 0L
        } else {
            return (System.nanoTime() - startTimeNs) / 1000
        }
    }

    interface Callback {
        fun onStateChange(state: RecordState)
        fun onError(e: Exception)
    }

    // TODO: Add crucial flag for errors that needed to take action
    sealed class RecorderError : Exception()
    class MuxerStopError : RecorderError()
    class MuxerAlreadyStartedError : RecorderError()
    class VideoTrackAlreadySetError : RecorderError()
    class AudioTrackNotSetError : RecorderError()
    class AudioTrackAlreadySetError : RecorderError()
    class OldAudioSampleError : RecorderError()
    class ErrorWritingAudioData(info: String) : RecorderError()
    class AudioRecordWhenSamplesInterceptedError : RecorderError()
    class AudioRecordNoDataError : RecorderError()
    class VideoEncoderInitWrongStateError : RecorderError()
}
