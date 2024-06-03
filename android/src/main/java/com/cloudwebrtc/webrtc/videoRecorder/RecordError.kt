package com.cloudwebrtc.webrtc.videoRecorder

data class RecordError(
    val code: String,
    val message: String?,
    val details: Map<String, String>? = null

) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "code" to code,
            "message" to message,
            "details" to details
        )
    }
}
