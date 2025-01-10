package com.cloudwebrtc.webrtc.videoRecorder

public enum class RecordEventType {
    idle,
    starting,
    recording,
    stop,
    error,
    result;

    companion object {
        fun fromState(state: RecordState): RecordEventType = when (state) {
            RecordState.idle -> idle
            RecordState.starting -> starting
            RecordState.recording -> recording
            RecordState.disposing -> stop
        }
    }
}