package com.cloudwebrtc.webrtc.detection

import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.nio.ByteBuffer
import kotlin.concurrent.thread
import kotlin.math.abs

class PixelDetection(private val detectionThreshold: Int) {
    companion object {
        const val xBoxes = 15
        const val yBoxes = 10
    }

    private var previous: Array<IntArray>? = null
    private var width: Int = 0
    private var height: Int = 0
    private var isSizeChanged = true
    private var xBoxSize = 0
    private var yBoxSize = 0
    private var pixelInBox = 0
    private var rowStride = 0


    fun detect(
        yByteBuffer: ByteBuffer,
        width: Int,
        height: Int,
        rowStride: Int,

        result: (List<Rect>) -> Unit
    ) {
        this.rowStride = rowStride
        if (width != this.width || height != this.height) {
            this.width = width
            this.height = height
            isSizeChanged = true
        } else {
            isSizeChanged = false
        }
        thread {
            calcBixPixelsMatrix(yByteBuffer, result)
        }
    }

    private fun calcBixPixelsMatrix(
        buffer: ByteBuffer,
        result: (List<Rect>) -> Unit
    ) {
        val list = mutableListOf<Rect>()
        xBoxSize = width / xBoxes
        yBoxSize = height / yBoxes
        pixelInBox = xBoxSize * yBoxSize
        val currentArray = Array(height) { IntArray(width) }
        for (y in 0 until yBoxes) {
            for (x in 0 until xBoxes) {
                val rect =
                    Rect(x * xBoxSize, y * yBoxSize, (x + 1) * xBoxSize, (y + 1) * yBoxSize)
                val color = getRectAverageLuma(
                    buffer = buffer,
                    xBoxNum = x,
                    yBoxNum = y
                )
                currentArray[y][x] = color
                if (!isSizeChanged) {
                    previous?.let {
                        val prevColor = it[y][x];
                        if (abs(prevColor - color) > this.detectionThreshold) {
                            list.add(rect)
                        }
                    }
                }
            }
        }
        previous = currentArray
        Handler(Looper.getMainLooper()).post {
            result.invoke(list)
        }
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
                color += (buffer[yOffset + xOffset + x])
            }
        }
        return (color / pixelInBox) + 127
    }

}
