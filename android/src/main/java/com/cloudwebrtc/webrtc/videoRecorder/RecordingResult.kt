package com.cloudwebrtc.webrtc.videoRecorder



data class RecordingResult(
   val recordId: String,
    val videoPath: String,
    val durationMs: Long,
    val rotationDegree: Int,
    val detection: Map<String, Any?>?

) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "recordId" to recordId,
            "video" to videoPath,
            "duration" to durationMs,
            "rotation" to rotationDegree,
            "detection" to detection
        )
    }
}