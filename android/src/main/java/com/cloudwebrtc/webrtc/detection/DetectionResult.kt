package com.cloudwebrtc.webrtc.detection

data class DetectionResult(val detectedList: List<LumaRect>, val aspectRatio: Double) {
    fun toMap(): Map<String, Any> = hashMapOf(
        "detected" to detectedList.map { it.toMap() },
        "aspect" to aspectRatio
    )
}
