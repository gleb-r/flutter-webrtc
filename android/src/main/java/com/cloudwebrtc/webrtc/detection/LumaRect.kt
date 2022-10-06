package com.cloudwebrtc.webrtc.detection

import android.graphics.RectF

data class LumaRect(val rect: RectF, val luma: Int) {
    fun toMap(): Map<String,Any> =
        hashMapOf(
            "l" to rect.left.toDouble(),
            "t" to rect.top.toDouble(),
            "r" to rect.right.toDouble(),
            "b" to rect.bottom.toDouble(),
            "c" to luma)
}
