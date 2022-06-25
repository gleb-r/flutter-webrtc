package com.cloudwebrtc.webrtc.detection

import android.graphics.RectF
import com.cloudwebrtc.webrtc.detection.PixelDetection.Companion.xBoxes
import com.cloudwebrtc.webrtc.detection.PixelDetection.Companion.yBoxes
import org.webrtc.VideoFrame
import java.nio.ByteBuffer
import kotlin.math.abs

class PixelDetection {
    companion object {
        const val xBoxes = 16
        const val yBoxes = 12
    }

    private var previousMatrix: Array<IntArray>? = null
    private var prevWidth: Int = 0
    private var prevHeight: Int = 0
    private var prevRotation = 0

    private var sizeNotChanged = false
    private var xBoxSize = 0
    private var yBoxSize = 0
    private var pixelInBox = 0
    private var box = RectF(0f, 0f, 0f, 0f)
    private var aspectRatio: Double = 1.0

    private fun xCount(rotation: Int) = when (rotation) {
        90, 270 -> yBoxes
        else -> xBoxes
    }


    private fun yCount(rotation:Int) = when (rotation) {
        90, 270 -> xBoxes
        else -> yBoxes
    }


    fun detect(
        buffer: VideoFrame.I420Buffer,
        rotation: Int,
        detectionLevel: Int,
        result: (DetectionResult) -> Unit
    ) {
        val height = buffer.height
        val width = buffer.width
        val detectionDiff = getDetectionDiff(detectionLevel)
        sizeNotChanged = width == prevWidth && height == prevHeight && rotation == prevRotation
        if (!sizeNotChanged) {
            this.prevWidth = width
            this.prevHeight = height
            this.prevRotation = rotation
            xBoxSize = width / xBoxes
            yBoxSize = height / yBoxes
            pixelInBox = xBoxSize * yBoxSize
            aspectRatio = when (rotation) {
                90, 270 -> height.toDouble() / width
                else -> width.toDouble() / height
            }
        }
        val detectionList = mutableListOf<Square>()
        val currentMatrix = Array(height) { IntArray(width) }
        for (y in 0 until yBoxes) {
            for (x in 0 until xBoxes) {
                val luma = getBoxAverageLuma(
                    buffer = buffer.dataY,
                    rowStride = buffer.strideY,
                    xBoxNum = x,
                    yBoxNum = y
                )
                currentMatrix[y][x] = luma
                if (sizeNotChanged) {
                    previousMatrix?.let {
                        val prevColor = it[y][x];
                        if (abs(prevColor - luma) > detectionDiff) {
                            detectionList.add(Square(x, y).rotate(rotation))
                        }
                    }
                }
            }
        }
        buffer.release()
        previousMatrix = currentMatrix
        result(DetectionResult(
            detectedList = detectionList,
            aspectRatio =  aspectRatio,
            xCount =  xCount(rotation),
            yCount = yCount(rotation)))
    }

    fun resetPrevious() {
        previousMatrix = null
        prevWidth = 0
        prevHeight = 0
        prevRotation = 0
    }

    private fun getDetectionDiff(level: Int) =
        when (level) {
            1 -> 25
            2 -> 14
            3 -> 5
            4 -> 3
            5 -> 2
            else -> 5
        }

    private fun RectF.scale(x: Float, y: Float): RectF =
        RectF(left * x, top * y, right * x, bottom * y)

    private fun RectF.move(x: Float, y: Float): RectF =
        RectF(left + x, top + y, right + x, bottom + y)

    private fun RectF.rotate(degree: Int): RectF = when (degree) {
        270 -> RectF(top, 1 - right, bottom, 1 - left)
        180 -> RectF(1 - right, 1 - bottom, 1 - left, 1 - top)
        90 -> RectF(1 - bottom, left, 1 - top, right)
        else -> RectF(left, top, right, bottom)
    }

    private fun Square.rotate(degree: Int): Square = when (degree) {
        270 -> Square(y, xBoxes - x - 1)
        180 -> Square(xBoxes - x - 1, yBoxes - 1 - y)
        90 -> Square(yBoxes - 1 - y, x)
        else -> this
    }


    private fun getBoxAverageLuma(
        buffer: ByteBuffer,
        xBoxNum: Int,
        yBoxNum: Int,
        rowStride: Int
    ): Int {
        var color = 0
        val yOffset = yBoxNum * yBoxSize * rowStride
        val xOffset = xBoxNum * xBoxSize
        for (y in 0 until yBoxSize) {
            for (x in 0 until xBoxSize) {
                val index = yOffset + y * rowStride + xOffset + x
                val luma = buffer[index].toUByte().toInt()
                color += luma
            }
        }
        return color / pixelInBox
    }

}
