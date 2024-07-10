package com.cloudwebrtc.webrtc.videoRecorder

import android.util.Log
import com.cloudwebrtc.webrtc.detection.DetectionResult

public data class DetectionData(
    val frames: MutableMap<String, List<String>>,
    val aspect: Double,
    val xCount: Int,
    val yCount: Int,
    val frameInterval: Int,
) {

    fun toMap(): Map<String, Any> {
        return mapOf(
            "f" to frames,
            "a" to aspect,
            "x" to xCount,
            "y" to yCount,
            "i" to frameInterval,
        )
    }


    constructor(detectionResult: DetectionResult, frameIndex: String, frameInterval: Int) : this(
        frames = mutableMapOf(frameIndex to detectionResult.detectedList.map { it.toString() }),
        aspect = detectionResult.aspectRatio,
        xCount = detectionResult.xCount,
        yCount = detectionResult.yCount,
        frameInterval = frameInterval
    )

    fun addFrame(frameIndex: String, detectionResult: DetectionResult) {
        if (detectionResult.xCount != xCount || detectionResult.yCount != yCount) {
            Log.e("Motion detection","DetectionData: xCount or yCount not match")
            return
        }
        frames[frameIndex] = detectionResult.detectedList.map { it.toString() }
    }

}
