import 'dart:async';


import 'package:flutter_webrtc/src/native/video_recorder/recording_state.dart';

import '../../../flutter_webrtc.dart';

abstract class IVideoRecorder {
  IVideoRecorder({
    required this.onError,
    required this.onRecorded,
  });

  Future<bool> start({
    required String dirPath,
    required MediaStream mediaStream,
    required bool enableAudio,
  });

  Future<void> stop();

  final Function(Exception error) onError;
  final Function(RTCRecordResult result) onRecorded;

  Stream<RecordingState> get recordStateStream;

  RecordingState get currentState;

  DetectionData? detectionOnVideo;

  Future<void> dispose();
}
