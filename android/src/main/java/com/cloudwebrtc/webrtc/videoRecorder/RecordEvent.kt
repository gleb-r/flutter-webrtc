package com.cloudwebrtc.webrtc.videoRecorder

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
public data class RecordEvent (
    val type: RecordEventType,
    val data: JsonElement?
)
