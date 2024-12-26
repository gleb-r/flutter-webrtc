package com.cloudwebrtc.webrtc.videoRecorder

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaRecorder
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.CHANNEL_COUNT
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.DELAY_THRESHOLD_US
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.MIME_TYPE_AUDIO
import com.cloudwebrtc.webrtc.videoRecorder.AudioAsyncEncoder.AudioAsyncEncoderConst.SAMPLE_RATE
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.newSingleThreadContext
import org.webrtc.Logging
import org.webrtc.audio.JavaAudioDeviceModule
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs

class AudioAsyncEncoder(
    private val isLocal: Boolean,
    private val scope: CoroutineScope,
    private val listener: Callback
) {

    private object AudioAsyncEncoderConst {
        const val SAMPLE_RATE = 48000
        const val CHANNEL_COUNT = 1
        const val MIME_TYPE_AUDIO: String = "audio/mp4a-latm"
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


    init {
        if (isLocal) {
            initializeLocal()
        }
    }

    fun onSamplesReady(audioSamples: JavaAudioDeviceModule.AudioSamples) {
        Logging.d(TAG, "onSamplesReady()")
        if (isDisposed.get()) {
            Logging.e(TAG, "onSamplesReady: isDisposed")
            return
        }

        if (audioRecord != null) {
            Logging.e(TAG, "!!! audioRecord should be null on onSamplesReady")
            return
        }
        scope.launch(renderContext) {
            val audioEncoder = audioEncoder
            if (audioEncoder == null) {
                createAudioEncoder(
                    audioSamples.sampleRate,
                    audioSamples.channelCount
                )
                Logging.d(
                    TAG,
                    "Audio encoder is null, create new one. skip sample"
                )
                return@launch
            }
            if (!isStarted.get()) {
                Logging.d(TAG, "Encoder is not started, skip sample")
                return@launch
            }
            val index = inputBufferIndexQueue.poll()
            if (index == null) {
                Logging.e(TAG, "!!!! Index is null, skip sample")
                return@launch
            }
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

    /// because audioSamples appeared with unsustainable time interval,
    /// we need to calculate the presentation time based on sample duration
    private fun calculatePresentationTimeUs(audioSamples: JavaAudioDeviceModule.AudioSamples): Long {
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

    private fun JavaAudioDeviceModule.AudioSamples.durationUs(): Long {
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
    }

    @SuppressLint("MissingPermission")
    private fun initializeLocal() {
        val audioRecord = AudioRecord.Builder()
            .setAudioSource(MediaRecorder.AudioSource.DEFAULT)
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                    .build()
            )
            // TODO: from AudioRecord.getMinBufferSize()
            .setBufferSizeInBytes(SAMPLE_RATE * 2)
            .build()

        audioRecord.startRecording()
        this.audioRecord = audioRecord
        scope.launch {
            createAudioEncoder(SAMPLE_RATE, CHANNEL_COUNT)
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
        // TODO: determine bit rate
        audioFormat.setInteger(MediaFormat.KEY_BIT_RATE, 64 * 1024)
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
            val audioRecord = audioRecord
            if (audioRecord == null) {
                Logging.e(TAG, "!!! audioRecord is null")
                return
            }
            val bytesRead =
                audioRecord.read(inputBuffer, inputBuffer.remaining())
            if (bytesRead > 0) {
                codec.queueInputBuffer(
                    index,
                    0,
                    bytesRead,
                    // TODO: try to use calc value from frequency
                    listener.presentationTimeUs(),
                    0
                )
            } else {
                Logging.e(
                    TAG,
                    "!!!readData: read audioRecord failed, bytesRead: $bytesRead"
                )
            }
            // TODO: EOS flag
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
            // TODO: send Do something
        }

        override fun onOutputFormatChanged(
            codec: MediaCodec,
            format: MediaFormat
        ) {
            Logging.d(
                TAG,
                "Output format changed: $format"
            )
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
    }
}