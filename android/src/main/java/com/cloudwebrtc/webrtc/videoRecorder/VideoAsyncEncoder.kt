package com.cloudwebrtc.webrtc.videoRecorder

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import com.cloudwebrtc.webrtc.utils.EglUtils
import com.cloudwebrtc.webrtc.utils.LogHelper.currentTime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.newSingleThreadContext
import org.webrtc.EglBase
import org.webrtc.GlRectDrawer
import org.webrtc.Logging
import org.webrtc.VideoFrame
import org.webrtc.VideoFrameDrawer
import org.webrtc.VideoSink
import java.nio.ByteBuffer

internal class VideoAsyncEncoder(
    private val scope: CoroutineScope,
    private val callback: Callback
) : VideoSink {
    private object VideoConst {
        // H.264 Advanced Video Coding
        const val MIME_TYPE_VIDEO: String = "video/avc"
        const val FRAME_RATE = 24
        const val I_FRAME_INTERVAL_SEC = 1
    }

    private var encoder: MediaCodec? = null
    private var eglBase: EglBase? = null
    private var frameDrawer: VideoFrameDrawer? = null
    private var drawer: GlRectDrawer? = null

    @Volatile
    private var state: EncoderState = EncoderState.IDLE
        set(value) {
            field = value
            Logging.d(TAG, "State changed to: $value")
        }

    private val TAG = "VideoEncoder"
    private val renderContext = newSingleThreadContext("RenderContext")

    internal interface Callback {
        fun saveData(
            encodedData: ByteBuffer,
            bufferInfo: MediaCodec.BufferInfo
        )

        fun addTrack(mediaFormat: MediaFormat)

        fun onError(e: Exception)
    }

    enum class EncoderState {
        IDLE,
        INITIALIZING,
        STARTING,
        STARTED,
        SHOULD_STOP,
        STOPPED,
        DISPOSED
    }


    override fun onFrame(frame: VideoFrame?) {
        if (frame == null) {
            return
        }
        when (state) {
            EncoderState.IDLE ->
                initVideoEncoder(frame.rotatedWidth, frame.rotatedHeight)

            EncoderState.STARTED -> drawFrame(frame)
            EncoderState.INITIALIZING,
            EncoderState.STARTING,
            EncoderState.STOPPED,
            EncoderState.SHOULD_STOP,
            EncoderState.DISPOSED ->
                Logging.d(TAG, " Skip frame in state: $state")
        }
    }

    private fun drawFrame(frame: VideoFrame) {
        frameRotation = frame.rotation
        try {
            frame.retain()
        } catch (e: IllegalStateException) {
            Logging.e(TAG, "$currentTime IllegalRefCountException: $e")
            return
        }
        scope.launch(renderContext) {
            // TODO:  android.opengl.GLException: eglMakeCurrent failed: 0x3000
            eglBase?.makeCurrent()
            // TODO: is size params needed?
            // TODO: could be error :"java.lang.RuntimeException: glCreateShader() failed. GLES20 error: 0"
            frameDrawer = VideoFrameDrawer()
            frameDrawer?.drawFrame(
                frame,
                drawer,
            )
            frame.release()
            eglBase?.swapBuffers()
        }
    }


    var frameRotation: Int? = null
        set(value) {
            if (field != null && field != value) {
                Logging.d(
                    TAG,
                    "!!! Frame rotation changed from $field to $value"
                )
                // TODO: handle rotation change
            }
            field = value
        }


    fun dispose() {
        if (state == EncoderState.IDLE ||
            state == EncoderState.DISPOSED ||
            state == EncoderState.STOPPED
        ) {
            return
        }
        if (state == EncoderState.STARTING) {
            state = EncoderState.SHOULD_STOP
            Logging.e(TAG, "!!!!! Dispose in STARTING state")
            return
        }
        if (state == EncoderState.INITIALIZING) {
            state = EncoderState.STOPPED
            encoder?.release()
            encoder = null
            return
        }
        state = EncoderState.STOPPED
        encoder?.signalEndOfInputStream()
        encoder?.stop()
        encoder?.setCallback(null)
        encoder?.release()
        encoder = null
        // TODO: store it and reuse ?
        frameDrawer?.release()
        drawer?.release()
        eglBase?.release()
        state = EncoderState.DISPOSED
        renderContext.close()
    }


    private fun initVideoEncoder(width: Int, height: Int) {
        if (state != EncoderState.IDLE) {
            callback.onError(AsyncFileRenderer.VideoEncoderInitWrongStateError())
            return
        }
        state = EncoderState.INITIALIZING
        val videoFormat = MediaFormat.createVideoFormat(
            VideoConst.MIME_TYPE_VIDEO,
            width,
            height
        )
        videoFormat.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
        )
        videoFormat.setInteger(
            MediaFormat.KEY_BIT_RATE,
            calculateBitrate(width, height)
        )
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
        scope.launch(renderContext) {
            if (state != EncoderState.INITIALIZING) {
                return@launch
            }
            state = EncoderState.STARTING
            val eglBase = EglBase.create(
                EglUtils.getRootEglBaseContext(),
                EglBase.CONFIG_RECORDABLE
            )
            this@VideoAsyncEncoder.eglBase = eglBase
            eglBase.createSurface(encoder.createInputSurface())
            eglBase.makeCurrent()
            drawer = GlRectDrawer()
            encoder.start()
            if (state == EncoderState.SHOULD_STOP) {
                dispose()
                return@launch
            }
            state = EncoderState.STARTED
        }
    }

    private fun calculateBitrate(width: Int, height: Int): Int {
        val bbp = 0.1
        val pixelPerSecond = 30 * width * height
        return (pixelPerSecond * bbp).toInt()
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
            if (state != EncoderState.STARTED) {
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
                callback.saveData(encodedData, info)
            } else {
                Logging.e(TAG, "Output buffer size is 0")
            }
            try {
                codec.releaseOutputBuffer(index, false)
            } catch (e: IllegalStateException) {
                Logging.e(TAG, "$currentTime Release output buffer error: $e")
            }

            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                Logging.d(TAG, "End of stream")
                state = EncoderState.STOPPED
            }
        }

        override fun onError(
            codec: MediaCodec,
            e: MediaCodec.CodecException
        ) {
            callback.onError(e)
        }

        override fun onOutputFormatChanged(
            codec: MediaCodec,
            format: MediaFormat
        ) {
            callback.addTrack(format)
        }
    }
}

