package com.cloudwebrtc.webrtc.videoRecorder
public enum class RecordEventType {
    idle,
    stating,
    recording,
    stop,
    error,
    result;

    companion object {
      public fun fromState(state: RecordState): RecordEventType = when (state) {
          RecordState.idle -> RecordEventType.idle
          RecordState.starting -> RecordEventType.stating
          RecordState.recording -> RecordEventType.recording
          RecordState.stop -> RecordEventType.stop
      }
    }
}