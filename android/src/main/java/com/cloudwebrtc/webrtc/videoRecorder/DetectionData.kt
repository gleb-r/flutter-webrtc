package com.cloudwebrtc.webrtc.videoRecorder

import com.cloudwebrtc.webrtc.detection.DetectionResult

public data class DetectionData(
    val frames: MutableMap<String, List<String>>,
    val aspect: Double,
    val xCount: Int,
    val yCount: Int,
) {

    fun toMap(): Map<String, Any> {
        return mapOf(
            "f" to frames,
            "a" to aspect,
            "x" to xCount,
            "y" to yCount,
        )
    }


    constructor(detectionResult: DetectionResult, frameIndex: String) : this(
        frames = mutableMapOf(frameIndex to detectionResult.detectedList.map { it.toString() }),
        aspect = detectionResult.aspectRatio,
        xCount = detectionResult.xCount,
        yCount = detectionResult.yCount,
    )

    fun addFrame(frameIndex: String, detectionResult: DetectionResult) {
        if (detectionResult.xCount != xCount || detectionResult.yCount != yCount) {
            throw IllegalArgumentException("DetectionData: xCount or yCount not match")
        }
        frames[frameIndex] = detectionResult.detectedList.map { it.toString() }
    }

}
