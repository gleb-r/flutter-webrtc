package com.cloudwebrtc.webrtc.videoRecorder

import com.cloudwebrtc.webrtc.detection.DetectionResult
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class DetectionData(
    @SerialName("f") val frames: MutableMap<String, List<String>>,
    @SerialName("a") val aspect: Double,
    @SerialName("x") val xCount: Int,
    @SerialName("y") val yCount: Int,
) {


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
