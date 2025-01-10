package com.cloudwebrtc.webrtc.videoRecorder

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaRecorder
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.BIT_RATE
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.CHANNEL_COUNT
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.DELAY_THRESHOLD_US
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.MIME_TYPE_AUDIO
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.SAMPLE_RATE
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.newSingleThreadContext
import org.webrtc.Logging
import org.webrtc.audio.JavaAudioDeviceModule.AudioSamples
import org.webrtc.audio.JavaAudioDeviceModule.SamplesReadyCallback
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs

class AudioAsyncEncoder(
    private val isLocal: Boolean,
    private val scope: CoroutineScope,
    private val listener: Callback
) : SamplesReadyCallback {

    private object AudioAsyncEncoderConst {
        const val SAMPLE_RATE = 48000
        const val CHANNEL_COUNT = 1
        const val MIME_TYPE_AUDIO: String = "audio/mp4a-latm"

        // 64 kbps bitrate - middle quality from mono 48 kHz audio
        const val BIT_RATE = 64 * 1024
        const val DELAY_THRESHOLD_US = 40_000L
    }

    private val TAG = "AudioAsyncEncoder"
    private var audioRecord: AudioRecord? = null
    private var audioEncoder: MediaCodec? = null
    private val isDisposed = AtomicBoolean(false)
    private val inputBufferIndexQueue = ConcurrentLinkedQueue<Int>()

    @Volatile
    private var isStarted = AtomicBoolean(false)
    private val renderContext = newSingleThreadContext("RenderContext")


    override fun onWebRtcAudioRecordSamplesReady(audioSamples: AudioSamples) {
        if (isDisposed.get()) {
            return
        }

        if (audioRecord != null) {
            listener.onError(AsyncFileRenderer.AudioRecordWhenSamplesInterceptedError())
            return
        }
        scope.launch(renderContext) {
            val audioEncoder = audioEncoder
            if (audioEncoder == null) {
                createAudioEncoder(
                    audioSamples.sampleRate,
                    audioSamples.channelCount
                )
                return@launch
            }
            val index = inputBufferIndexQueue.poll() ?: return@launch
            val inputBuffer = audioEncoder.getInputBuffer(index)
            if (inputBuffer == null) {
                Logging.e(TAG, "Input buffer is null")
                return@launch
            }
            inputBuffer.clear()
            inputBuffer.put(audioSamples.data)
            val presentationTimeUs = calculatePresentationTimeUs(audioSamples)
            audioEncoder.queueInputBuffer(
                index,
                0,
                audioSamples.data.size,
                presentationTimeUs,
                0
            )
        }
    }

    private var sampleTimeUs = 0L

    /// because audioSamples appeared with unsustainable time interval, but have known duration
    /// we can to calculate the presentation time by incrementing the previous time by the duration
    /// if sampleTimeUs go to far from the main presentation time, we update it
    private fun calculatePresentationTimeUs(audioSamples: AudioSamples): Long {
        val mainPresentationTimeUs = listener.presentationTimeUs()
        if (sampleTimeUs == 0L) {
            sampleTimeUs = mainPresentationTimeUs
        } else {
            sampleTimeUs += audioSamples.durationUs()
            val diff =
                abs(sampleTimeUs - mainPresentationTimeUs)
            if (diff > DELAY_THRESHOLD_US) {
                sampleTimeUs = mainPresentationTimeUs
                Logging.d(
                    TAG,
                    "Difference between audio and video time is too big, update audio time"
                )
            }
        }
        return sampleTimeUs
    }

    private fun AudioSamples.durationUs(): Long {
        // calculate duration in microseconds form sample size and sample rate
        return (this.data.size * 1_000_000 / sampleRate / 2).toLong()
    }

    fun dispose() {
        Logging.d(TAG, "dispose()")
        isDisposed.set(true)
        inputBufferIndexQueue.clear()
        audioRecord?.stop()
        audioRecord?.release()
        audioEncoder?.stop()
        audioEncoder?.release()
        renderContext.close()
    }

    @SuppressLint("MissingPermission")
    fun initializeLocal() {
        val bufferSize = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val audioRecord = AudioRecord.Builder()
            .setAudioSource(MediaRecorder.AudioSource.DEFAULT)
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                    .build()
            )
            .setBufferSizeInBytes(bufferSize)
            .build()


        this.audioRecord = audioRecord
        scope.launch {
            createAudioEncoder(SAMPLE_RATE, CHANNEL_COUNT)
            audioRecord.startRecording()
            // TODO: start audioRecord here?
        }
    }

    private var isEncoderCreating = AtomicBoolean(false)

    private fun createAudioEncoder(sampleRate: Int, channelCount: Int) {
        if (isEncoderCreating.get()) {
            return
        }
        isEncoderCreating.set(true)
        val audioEncoder = MediaCodec.createEncoderByType(MIME_TYPE_AUDIO)
        this.audioEncoder = audioEncoder
        val audioFormat = MediaFormat.createAudioFormat(
            MIME_TYPE_AUDIO,
            sampleRate,
            channelCount
        )
        audioFormat.setInteger(
            MediaFormat.KEY_BIT_RATE,
            BIT_RATE
        )
        audioFormat.setInteger(
            MediaFormat.KEY_AAC_PROFILE,
            MediaCodecInfo.CodecProfileLevel.AACObjectLC
        )
        audioEncoder.setCallback(encoderCallback)
        audioEncoder.configure(
            audioFormat,
            null,
            null,
            MediaCodec.CONFIGURE_FLAG_ENCODE
        )
        audioEncoder.start()
        isStarted.set(true)
    }

    private val encoderCallback = object : MediaCodec.Callback() {
        override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
            if (isDisposed.get()) {
                return
            }
            if (!isLocal) {
                inputBufferIndexQueue.offer(index)
                return
            }
            val inputBuffer = codec.getInputBuffer(index)
            if (inputBuffer == null) {
                Logging.e(TAG, "inputBuffer is null")
                return
            }
            inputBuffer.clear()
            val audioRecord = audioRecord ?: return
            val bytesRead = audioRecord.read(
                inputBuffer,
                inputBuffer.remaining()
            )
            if (bytesRead == 0) {
                codec.queueInputBuffer(
                    index,
                    0,
                    0,
                    listener.presentationTimeUs(),
                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                )
                listener.onError(AsyncFileRenderer.AudioRecordNoDataError())
                return
            }
            codec.queueInputBuffer(
                index,
                0,
                bytesRead,
                listener.presentationTimeUs(),
                0
            )
        }

        override fun onOutputBufferAvailable(
            codec: MediaCodec,
            index: Int,
            info: MediaCodec.BufferInfo
        ) {
            val encodedData = codec.getOutputBuffer(index)
            if (encodedData == null) {
                Logging.e(TAG, "Encoded data is null")
                codec.releaseOutputBuffer(index, false)
                return
            }
            if (info.size != 0) {
                listener.saveData(encodedData, info)
            }
            codec.releaseOutputBuffer(index, false)
        }

        override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
            listener.onError(e)
        }

        override fun onOutputFormatChanged(
            codec: MediaCodec,
            format: MediaFormat
        ) {
            listener.addTrack(format)
        }
    }


    interface Callback {
        fun presentationTimeUs(): Long

        fun saveData(
            encodedData: ByteBuffer,
            bufferInfo: MediaCodec.BufferInfo
        )

        fun addTrack(mediaFormat: MediaFormat)

        fun onError(e: Exception)
    }
}