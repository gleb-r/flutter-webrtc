package com.cloudwebrtc.webrtc.utils

import java.text.SimpleDateFormat

object LogHelper {
    private val formatter = SimpleDateFormat("HH:mm:ss:SSS")
    val currentTime: String
        get() = "[${formatter.format(System.currentTimeMillis())}]"
}
