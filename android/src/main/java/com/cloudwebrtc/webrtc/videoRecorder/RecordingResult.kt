package com.cloudwebrtc.webrtc.videoRecorder

data class RecordingResult(
    val recordId: String,
    val videoPath: String,
    val durationMs: Long,
    val frameIntervalMs: Long,
    val rotationDegree: Int

) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "recordId" to recordId,
            "video" to videoPath,
            "rotation" to rotationDegree,
            "duration" to durationMs,
            "interval" to frameIntervalMs
        )
    }
}