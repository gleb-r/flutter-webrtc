import 'package:flutter_webrtc/src/native/video_recorder/record_event.dart';

enum RecordState {
  idle,
  starting,
  recording,
  stop,
  ;

  bool get isRecording =>
      this == RecordState.recording || this == RecordState.starting;

  static RecordState? fromEvent(RecordEvent event) {
    switch (event.type) {
      case RecordEventType.idle:
        return RecordState.idle;
      case RecordEventType.starting:
        return RecordState.starting;
      case RecordEventType.recording:
        return RecordState.recording;
      case RecordEventType.stop:
        return RecordState.stop;
      default:
        return null;
    }
  }
}
