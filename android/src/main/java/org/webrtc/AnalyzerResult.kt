package org.webrtc

import com.cloudwebrtc.webrtc.utils.ConstraintsMap

class AnalyzerResult(
    private val isCustomExposureOn: Boolean,
    private val isUltraBrightness: Boolean,
    private val exposureOffset: Float,
    private val currentDurationMs: Int,
    private val currentISO: Int,
    // max ISO from camera capabilities
    private val maxISO: Int,
    // max ISO in auto mode
    private val maxAutoISO: Int,
    // max exposure duration from camera capabilities
    private val maxDurationMs: Int,
    // max exposure duration in auto mode
    private val maxAutoDurationMs: Int,
) {
    fun toMap(): ConstraintsMap {
        val map = ConstraintsMap()
        map.putDouble("exposureOffset", exposureOffset.toDouble())
        map.putBoolean("isCustomExposureOn", isCustomExposureOn)
        map.putBoolean("isUltraBrightness", isUltraBrightness)
        map.putInt("currentDurationMs", currentDurationMs)
        map.putInt("currentISO", currentISO)
        map.putInt("maxISO", maxISO)
        map.putInt("maxAutoISO", maxAutoISO)
        map.putInt("maxDurationMs", maxDurationMs)
        map.putInt("maxAutoDurationMs", maxAutoDurationMs)
        return map
    }
}
