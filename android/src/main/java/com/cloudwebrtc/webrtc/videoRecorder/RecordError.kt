package com.cloudwebrtc.webrtc.videoRecorder

import kotlinx.serialization.Serializable

@Serializable
data class RecordError(
    val code: String,
    val message: String?,
    val details: Map<String, String>? = null
)
