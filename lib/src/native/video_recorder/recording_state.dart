import 'package:flutter_webrtc/src/native/video_recorder/record_event.dart';

enum RecordingState {
  idle,
  starting,
  recording,
  stop,
  ;

  bool get isRecording =>
      this == RecordingState.recording || this == RecordingState.starting;

  static RecordingState? fromEvent(RecordEvent event) {
    switch (event.type) {
      case RecordEventType.idle:
        return RecordingState.idle;
      case RecordEventType.starting:
        return RecordingState.starting;
      case RecordEventType.recording:
        return RecordingState.recording;
      case RecordEventType.stop:
        return RecordingState.stop;
      default:
        return null;
    }
  }
}
