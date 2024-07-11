import 'dart:async';

import 'package:flutter_webrtc/src/native/video_recorder/recording_state.dart';
import 'package:rxdart/rxdart.dart';

import '../../../flutter_webrtc.dart';

abstract class IVideoRecorder {
  IVideoRecorder({
    required this.onError,
    required this.onRecorded,
  });

  Future<bool> start({
    required String recordId,
    required String path,
    required MediaStream mediaStream,
    required bool enableAudio,
  });

  Future<void> stop();

  final Function(Exception error) onError;
  final Function(RTCRecordResult result) onRecorded;

  DetectionData? detectionOnVideo;

  Future<void> dispose() async {
    if (stateSubject.value.isRecording) {
      await stop();
    }
    await stateSubject.close();
  }

  final stateSubject = BehaviorSubject.seeded(RecordingState.idle);

  Stream<RecordingState> get recordStateStream => stateSubject.stream;

  RecordingState get currentState => stateSubject.value;
}
