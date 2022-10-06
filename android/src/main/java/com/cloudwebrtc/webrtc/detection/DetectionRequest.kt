package com.cloudwebrtc.webrtc.detection

import io.flutter.plugin.common.MethodCall

data class DetectionRequest(
    val enabled: Boolean,
    val level: Int,
) {
    companion object {
        fun fromMethodCall(call:MethodCall): DetectionRequest? {
            val enabled = call.argument<Boolean>("enabled")
            val level = call.argument<Int>("level")
            return if (enabled != null && level != null) {
                DetectionRequest(enabled, level)
            } else {
                null
            }
        }
    }
}
