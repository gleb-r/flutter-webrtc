package com.cloudwebrtc.webrtc.detection

data class DetectionResult(
    val detectedList: List<Square>,
    val aspectRatio: Double,
    val xCount: Int,
    val yCount: Int
) {
    fun toMap(): Map<String, Any> = hashMapOf(
        "detected" to detectedList.map { it.toString() },
        "aspect" to aspectRatio,
        "xCount" to xCount,
        "yCount" to yCount
    )
}
