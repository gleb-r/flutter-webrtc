package org.webrtc.video

import io.flutter.plugin.common.MethodCall
sealed class CustomExposureParams {

    val isCustomExposureOn: Boolean
        get() = this is CustomExposureOn || this is CustomExposureUltra


    val isCustomExposureUltra: Boolean
        get() = this is CustomExposureUltra

    val durationNs : Long
        get() = when(this){
            is CustomExposureOn -> durationMs.toLong() * 1_000_000
            is CustomExposureUltra -> durationMs.toLong() * 1_000_000
            else -> 0
        }

    val ISO : Int
        get() = when(this){
            is CustomExposureOn -> iso
            is CustomExposureUltra -> iso
            else -> 0
        }

    override fun toString() : String {
        return when(this){
            is CustomExposureOn -> "CustomExposureOn(durationMs=$durationMs, iso=$iso)"
            is CustomExposureUltra -> "CustomExposureUltra(durationMs=$durationMs, iso=$iso)"
            else -> "CustomExposureOff"
        }
    }


    class CustomExposureOff : CustomExposureParams()
    class CustomExposureOn(val durationMs: Int, val iso: Int) :
        CustomExposureParams()

    class CustomExposureUltra(val durationMs: Int, val iso: Int) :
        CustomExposureParams()

    companion object {
        fun create(methodCall: MethodCall): CustomExposureParams {
            val enabled = methodCall.argument<Boolean>("enable") ?: false
            if (!enabled) {
                return CustomExposureOff()
            }
            val durationMs = methodCall.argument<Int>("durationMs") ?: 0
            val iso = methodCall.argument<Int>("iso") ?: 0
            val ultraBrightness =
                methodCall.argument<Boolean>("ultraBrightness") ?: false
            return if (ultraBrightness) {
                CustomExposureUltra(durationMs, iso)
            } else {
                CustomExposureOn(durationMs, iso)
            }
        }
    }
}