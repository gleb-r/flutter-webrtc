package com.cloudwebrtc.webrtc.videoRecorder

import com.cloudwebrtc.webrtc.detection.DetectionResult
import com.cloudwebrtc.webrtc.detection.Square

data class DetectionWithIndex(
    val squares: List<Square>,
    val aspect: Double,
    val xCount: Int,
    val yCount: Int,
    val frameIndex: Int
) {
    fun toMap(): Map<String, Any> = mapOf(
        "l" to squares.map { it.toString() },
        "i" to frameIndex,
        "a" to aspect,
        "x" to xCount,
        "y" to yCount
    )

    constructor(detectionResult: DetectionResult, frameIndex: Int):this(
        squares = detectionResult.detectedList,
        aspect = detectionResult.aspectRatio,
        xCount = detectionResult.xCount,
        yCount = detectionResult.yCount,
        frameIndex = frameIndex
    )

}
