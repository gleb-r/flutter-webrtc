package com.cloudwebrtc.webrtc.videoRecorder

import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement

@Serializable
data class RecordingResult(
    @SerialName("recordId") val recordId: String,
    @SerialName("video") val videoPath: String,
    @SerialName("duration") val durationMs: Long,
    @SerialName("interval") val frameIntervalMs: Long,
    @SerialName("rotation") val rotationDegree: Int,
    @SerialName("detection") val detection: JsonElement?
)