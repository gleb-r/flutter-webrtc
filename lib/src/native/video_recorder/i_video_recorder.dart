import 'dart:async';

import 'package:flutter/services.dart';

import '../../../flutter_webrtc.dart';

abstract class IVideoRecorder {
  Future<bool> start({
    required String dirPath,
    required MediaStream mediaStream,
    required bool enableAudio,
  });

  Future<RTCRecordResult> stop();

  RTCDetectedFrames? detectionOnVideo;
}