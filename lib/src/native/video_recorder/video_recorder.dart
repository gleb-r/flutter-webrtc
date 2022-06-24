import 'dart:async';

import 'package:flutter/services.dart';

import '../../../flutter_webrtc.dart';

class VideoRecorder {
  RTCDetectedFrames? _detectionOnVideo;
  var _detectionIntervalMs = 300;

  Future<bool> start({
    required String path,
    required bool isLocal,
    required bool enableAudio,
    int detectionIntervalMs = 300,
  }) async {
    _detectionIntervalMs = detectionIntervalMs;
    final isStarted = await WebRTC.invokeMethod('startRecordVideo', {
      'path': path,
      'isLocal': isLocal,
      'enableAudio': enableAudio,
      'interval': detectionIntervalMs,
    });
    _listenEventChannel();
    return isStarted;
  }

  Future<RTCDetectedFrames?> stop() async {
    final videoDurationMs = await WebRTC.invokeMethod('stopRecordVideo');
    await _detectionSubscription?.cancel();
    final detection = _detectionOnVideo;
    detection?.durationMs = videoDurationMs;
    detection?.frameIntervalMs = _detectionIntervalMs;
    _detectionOnVideo = null;
    return detection;
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/detectionOnVideo');
  StreamSubscription? _detectionSubscription;

  void _listenEventChannel() {
    _detectionSubscription = _eventChannel
        .receiveBroadcastStream()
        .map(DetectionWithTime.fromMap)
        .listen((detection) {
      if (_detectionOnVideo == null) {
        _detectionOnVideo = RTCDetectedFrames.init(detection);
      } else {
        _detectionOnVideo?.addFrame(detection);
      }
    });
  }

  void dispose() {
    _detectionSubscription?.cancel();
  }
}
