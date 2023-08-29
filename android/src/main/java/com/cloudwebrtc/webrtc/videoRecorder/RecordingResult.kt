package com.cloudwebrtc.webrtc.videoRecorder

data class RecordingResult(
    val videoPath: String,
    val durationMs: Long,
    val frameIntervalMs: Long,
    val rotationDegree: Int

) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "video" to videoPath,
            "rotation" to rotationDegree,
            "duration" to durationMs,
            "interval" to frameIntervalMs
        )
    }
}
