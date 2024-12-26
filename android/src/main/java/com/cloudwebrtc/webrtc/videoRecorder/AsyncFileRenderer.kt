package com.cloudwebrtc.webrtc.videoRecorder

import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMuxer
import com.cloudwebrtc.webrtc.record.FirstFrameListener
import com.cloudwebrtc.webrtc.utils.LogHelper.currentTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.webrtc.Logging
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.audio.JavaAudioDeviceModule.AudioSamples
import org.webrtc.audio.JavaAudioDeviceModule.SamplesReadyCallback
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean


class AsyncFileRenderer(
    private val path: String,
    private var firstFrameListener: FirstFrameListener?,
    private val isLocal: Boolean,
    private val isAudioEnabled: Boolean
) : VideoSink, SamplesReadyCallback {
    private val TAG = "AsyncFileRenderer"

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


    fun dispose() {
        Logging.d(TAG, "$currentTime dispose()")
        videoEncoder.dispose()
        audioEncoder?.dispose()
        if (isMuxerStarted.get()) {
            mediaMuxer.stop()
        }
        mediaMuxer.release()
        // TODO: cancel renderScope
    }


    override fun onFrame(frame: VideoFrame?) {
        if (frame == null) {
            Logging.e(TAG, "$currentTime Frame is null")
            return
        }
        Logging.d(TAG, "$currentTime onFrame()")
        videoEncoder.onFrame(frame)
        firstFrameListener?.onFirstFrame(frame.rotation)
        firstFrameListener = null
    }

    override fun onWebRtcAudioRecordSamplesReady(audioSamples: AudioSamples) {
        val audioEncoder = audioEncoder ?: return
        audioEncoder.onSamplesReady(audioSamples)
    }

    private fun startMuxer() {
        if (isMuxerStarted.get()) {
            Logging.e(TAG, "$currentTime Muxer is already started")
            return
        }
        if (videoTrackIndex != -1 && (audioTrackIndex != -1 || !isAudioEnabled)) {
            mediaMuxer.start()
            isMuxerStarted.set(true)
            startTimeNs = System.nanoTime()
            Logging.d(TAG, "$currentTime Muxer started")
        }
    }

    private val videoCallback =
        object : VideoAsyncEncoder.OnOutputBufferListener {
            override fun saveData(
                encodedData: ByteBuffer,
                bufferInfo: MediaCodec.BufferInfo
            ) {
                if (!isMuxerStarted.get()) {
                    Logging.e(
                        TAG,
                        "$currentTime !!!Muxer is not started, skip writing video data"
                    )
                    return
                }
                bufferInfo.presentationTimeUs = presentationTimeUs()
                mediaMuxer.writeSampleData(
                    videoTrackIndex,
                    encodedData,
                    bufferInfo
                )
            }

            override fun addTrack(mediaFormat: MediaFormat) {
                if (videoTrackIndex != -1) {
                    Logging.e(
                        TAG,
                        "$currentTime !!!Video track index is already set, skip adding video track"
                    )
                    return
                }
                videoTrackIndex = mediaMuxer.addTrack(mediaFormat)
                startMuxer()
            }
        }

    private val audioCallback =
        object : AudioAsyncEncoder.Callback {
            override fun presentationTimeUs(): Long =
                this@AsyncFileRenderer.presentationTimeUs()

            override fun saveData(
                encodedData: ByteBuffer,
                bufferInfo: MediaCodec.BufferInfo
            ) {
                if (!isMuxerStarted.get()) {
                    Logging.e(
                        TAG,
                        "$currentTime !!!Muxer is not started, skip writing audio data"
                    )
                    return
                }
                if (audioTrackIndex == -1) {
                    Logging.e(
                        TAG,
                        "$currentTime !!!Audio track index is not set, skip writing audio data"
                    )
                    return
                }
                if (bufferInfo.presentationTimeUs == 0L) {
                    Logging.d(TAG, "Skip audio sample")
                    return
                }
                mediaMuxer.writeSampleData(
                    audioTrackIndex,
                    encodedData,
                    bufferInfo
                )
            }

            override fun addTrack(mediaFormat: MediaFormat) {
                if (audioTrackIndex != -1) {
                    Logging.e(
                        TAG,
                        "$currentTime !!!Audio track index is already set, skip adding audio track"
                    )
                    return
                }
                audioTrackIndex = mediaMuxer.addTrack(mediaFormat)
                startMuxer()
            }
        }

    init {
        if (isAudioEnabled) {
            audioEncoder =
                AudioAsyncEncoder(isLocal, renderScope, audioCallback)
        }
    }


    private fun presentationTimeUs(): Long {
        if (startTimeNs == 0L) {
            return 0L
        } else {
            return (System.nanoTime() - startTimeNs) / 1000
        }
    }

}

