package com.cloudwebrtc.webrtc.detection

import android.graphics.Rect
import android.util.Log
import org.webrtc.VideoFrame
import org.webrtc.VideoSink
import org.webrtc.VideoTrack

class MotionDetection : VideoSink {
    private var videoTrack: VideoTrack? = null
    private var detectionLevel = 5
    private var pixelDetection: PixelDetection? = null
    private var callback: Callback? = null

    fun starDetection(videoTrack: VideoTrack, detectionLevel: Int, callback: Callback) {
        this.videoTrack = videoTrack
        this.detectionLevel = detectionLevel
        this.pixelDetection = PixelDetection(detectionLevel)
        this.callback = callback
        videoTrack.addSink(this)
    }

    fun stopDetection() {
        videoTrack?.removeSink(this)
        videoTrack = null
        callback = null
    }


    override fun onFrame(videoFrame: VideoFrame) {
        val callback = this.callback ?: return
        val i420Buffer = videoFrame.buffer.toI420() ?: return
        val yBuffer = i420Buffer.dataY
        Log.d("TAG", "buffer W:${videoFrame.buffer.width} , H:${videoFrame.buffer.height}")
        Log.d("TAG", "frame W:${videoFrame.rotatedWidth} , H:${videoFrame.buffer.height}")
        Log.d("TAG", "i420buffer W:${i420Buffer.width} , H:${i420Buffer.height}")
        pixelDetection?.let {
            it.detect(
                yByteBuffer = yBuffer,
                width = videoFrame.buffer.width,
                height = videoFrame.buffer.height,
                rowStride = i420Buffer.strideY,
                result = { result -> callback.detect(result) }
            )
        }


    }

    interface Callback {
        fun detect(squares: List<Rect>)
    }

}
