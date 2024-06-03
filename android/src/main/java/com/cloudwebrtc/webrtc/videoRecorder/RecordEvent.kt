package com.cloudwebrtc.webrtc.videoRecorder

public data class RecordEvent (
    val type: RecordEventType,
    val data: Map<String, Any?>?
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "type" to type.name,
            "data" to data
        )
    }
}
