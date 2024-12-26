package com.cloudwebrtc.webrtc.videoRecorder

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.os.Handler
import android.os.HandlerThread
import com.cloudwebrtc.webrtc.utils.EglUtils
import com.cloudwebrtc.webrtc.utils.LogHelper.currentTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import org.webrtc.EglBase
import org.webrtc.GlRectDrawer
import org.webrtc.Logging
import org.webrtc.VideoFrame
import org.webrtc.VideoFrameDrawer
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

internal class VideoAsyncEncoder(
    private val scope: CoroutineScope,
    private val listener: OnOutputBufferListener
) {
    private object VideoConst {
        val MIME_TYPE_VIDEO: String =
            "video/avc" // H.264 Advanced Video Coding
        val FRAME_RATE = 30
        val I_FRAME_INTERVAL_SEC = 1

        // TODO: determine bit rate from video quality
        val BIT_RATE = 6000000
    }

    private var encoder: MediaCodec? = null
    private var eglBase: EglBase? = null
    private val frameDrawer = VideoFrameDrawer()
    private var drawer: GlRectDrawer? = null

    @Volatile
    private var isStarted = AtomicBoolean(false)

    private val isDisposed = AtomicBoolean(false)
    private val TAG = "VideoEncoder"
    private val renderThread  = HandlerThread("VideoEncoder")
    private val renderHandler  by lazy {
        renderThread.start()
        Handler(renderThread.looper)
    }


    internal interface OnOutputBufferListener {
        fun saveData(
            encodedData: ByteBuffer,
            bufferInfo: MediaCodec.BufferInfo
        )

        fun addTrack(mediaFormat: MediaFormat)
    }

    // TODO: create encoder state enum

    fun onFrame(frame: VideoFrame) {
        if (isDisposed.get()) {
            return
        }


        if (encoder == null) {
            initVideoEncoder(frame.rotatedWidth, frame.rotatedHeight)
            Logging.d(
                TAG,
                "$currentTime Init encoder, skip frame"
            )
            return
        }
        if (!isStarted.get()) {
            Logging.d(
                TAG,
                "$currentTime Encoder is not started, skip frame"
            )
            return
        }
        renderHandler.post {
            try {
                frame.retain()
            } catch (e: IllegalStateException) {
                Logging.e(TAG, "$currentTime IllegalRefCountException: $e")
                return@post
            }
            // TODO: is size params needed?
            // TODO: could be error :"java.lang.RuntimeException: glCreateShader() failed. GLES20 error: 0"
            frameDrawer.drawFrame(
                frame,
                drawer,
            )
            frame.release()
            eglBase?.swapBuffers()
        }
    }

    fun dispose() {
        isDisposed.set(true)
        // TODO: test stop if not started
        encoder?.stop()
        encoder?.release()
        scope.launch {
            // TODO: store it and reuse ?
            frameDrawer.release()
            drawer?.release()
            eglBase?.release()
        }
    }

    private var isCreatingEncoder = AtomicBoolean(false)

    private fun initVideoEncoder(width: Int, height: Int) {
        if (isCreatingEncoder.get()) {
            Logging.d(TAG, "$currentTime Encoder is creating, skip init")
            return
        }
        isCreatingEncoder.set(true)
        val videoFormat = MediaFormat.createVideoFormat(
            VideoConst.MIME_TYPE_VIDEO,
            width,
            height
        )
        videoFormat.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
        )
        // TODO: determine bit rate
        videoFormat.setInteger(MediaFormat.KEY_BIT_RATE, VideoConst.BIT_RATE)
        videoFormat.setInteger(
            MediaFormat.KEY_FRAME_RATE,
            VideoConst.FRAME_RATE
        )
        videoFormat.setInteger(
            MediaFormat.KEY_I_FRAME_INTERVAL,
            VideoConst.I_FRAME_INTERVAL_SEC
        )
        val encoder = MediaCodec.createEncoderByType(VideoConst.MIME_TYPE_VIDEO)
        this.encoder = encoder
        // TODO: add handler to callback
        encoder.setCallback(videoCallback)
        encoder.configure(
            videoFormat,
            null,
            null,
            MediaCodec.CONFIGURE_FLAG_ENCODE
        )
        renderHandler.post {
            val eglBase = EglBase.create(
                EglUtils.getRootEglBaseContext(),
                EglBase.CONFIG_RECORDABLE
            )
            this@VideoAsyncEncoder.eglBase = eglBase
            eglBase.createSurface(encoder.createInputSurface())
            eglBase.makeCurrent()
            drawer = GlRectDrawer()
            encoder.start()
            this@VideoAsyncEncoder.isStarted = AtomicBoolean(true)
        }
    }

    private val videoCallback = object : MediaCodec.Callback() {
        override fun onInputBufferAvailable(
            codec: MediaCodec,
            index: Int
        ) {
            // not needed, we use surface input
        }

        override fun onOutputBufferAvailable(
            codec: MediaCodec,
            index: Int,
            info: MediaCodec.BufferInfo
        ) {
            if (isDisposed.get()) {
                return
            }
            val encodedData = codec.getOutputBuffer(index)
            if (encodedData == null) {
                Logging.e(TAG, "$currentTime Encoded data is null")
                codec.releaseOutputBuffer(index, false)
                return
            }
            if (info.size != 0) {
                encodedData.position(info.offset)
                encodedData.limit(info.offset + info.size)
                listener.saveData(encodedData, info)
            } else {
                Logging.e(TAG, "Output buffer size is 0")
            }
            codec.releaseOutputBuffer(index, false)
            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                Logging.d(TAG, "End of stream")
                isDisposed.set(true)
            }
        }

        override fun onError(
            codec: MediaCodec,
            e: MediaCodec.CodecException
        ) {
            // TODO: handle error
            Logging.e(TAG, "$currentTime MediaCodec error: $e")
        }

        override fun onOutputFormatChanged(
            codec: MediaCodec,
            format: MediaFormat
        ) {
            Logging.d(
                TAG,
                "$currentTime Output format changed: $format"
            )
            listener.addTrack(format)
        }
    }
}

