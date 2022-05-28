package com.cloudwebrtc.webrtc.detection

import android.graphics.Rect
import android.graphics.RectF
import android.os.Handler
import android.os.Looper
import org.webrtc.VideoFrame
import java.nio.ByteBuffer
import kotlin.concurrent.thread
import kotlin.experimental.and
import kotlin.math.abs

class PixelDetection(private val detectionThreshold: Int) {
    companion object {
        const val xBoxes = 16
        const val yBoxes = 12
    }

    private var previous: Array<IntArray>? = null
    private var width: Int = 0
    private var height: Int = 0
    private var isSizeChanged = true
    private var xBoxSize = 0
    private var yBoxSize = 0
    private var pixelInBox = 0
    private var rowStride = 0
    private var rotation = 0


    fun detect(
        buffer: VideoFrame.I420Buffer,
        rotation: Int,
        result: (List<Pair<RectF, Int>>) -> Unit
    ) {
        this.rowStride = buffer.strideY
        this.rotation = rotation
        if (buffer.width != this.width || buffer.height != this.height) {
            this.width = buffer.width
            this.height = buffer.height
            isSizeChanged = true
        } else {
            isSizeChanged = false
        }
        thread {
            calcBixPixelsMatrix(buffer, result)
        }
    }

    private fun calcBixPixelsMatrix(
        buffer: VideoFrame.I420Buffer,
        result: (List<Pair<RectF, Int>>) -> Unit
    ) {
        val list = mutableListOf<Pair<RectF, Int>>()
        xBoxSize = width / xBoxes
        yBoxSize = height / yBoxes
        pixelInBox = xBoxSize * yBoxSize
        val box = RectF(0f, 0f, xBoxSize.toFloat(), yBoxSize.toFloat())

        val currentArray = Array(height) { IntArray(width) }
        for (y in 0 until yBoxes) {
            for (x in 0 until xBoxes) {
                val rect = box.move(x * xBoxSize.toFloat(), y * yBoxSize.toFloat())
                    .scale(1 / width.toFloat(), 1 / height.toFloat())
                    .rotate(rotation)

                val luma = getRectAverageLuma(
                    buffer = buffer.dataY,
                    xBoxNum = x,
                    yBoxNum = y
                )
                currentArray[y][x] = luma
                if (!isSizeChanged) {
                    previous?.let {
                        val prevColor = it[y][x];
                        if (abs(prevColor - luma) > this.detectionThreshold) {
                        list.add(rect to luma)
                        }
                    }
                }
            }
        }
        buffer.release()
        previous = currentArray
        Handler(Looper.getMainLooper()).post {
            result.invoke(list)
        }
    }

    private fun RectF.scale(x: Float, y: Float): RectF =
        RectF(left * x, top * y, right * x, bottom * y)

    private fun RectF.move(x: Float, y: Float): RectF =
        RectF(left + x, top + y, right + x, bottom + y)

    private fun RectF.rotate(degree: Int) = when (degree) {
        270 -> RectF(top, 1 - right, bottom, 1 - left)
        180 -> RectF(1 - right, 1 - bottom, 1 - left, 1 - top)
        90 -> RectF(1 - bottom, left, 1 - top, right)
        else -> RectF(left, top, right, bottom)
    }


    private fun getRectAverageLuma(
        buffer: ByteBuffer,
        xBoxNum: Int,
        yBoxNum: Int
    ): Int {
        var color = 0
        val xOffset = (xBoxNum * xBoxSize)
        for (y in 0 until yBoxSize) {
            val yOffset = (yBoxNum * yBoxSize + y) * rowStride
            for (x in 0 until xBoxSize) {
                val luma = buffer[yOffset + xOffset + x].toInt()
                val luma2 = if (luma >= 0) luma  else 255 + luma
                color += luma2
            }
        }
        return (color / pixelInBox)
    }

}
