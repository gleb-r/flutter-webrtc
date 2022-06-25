import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/src/native/video_recorder/recorder_result.dart';

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
    if (isStarted) {
      _listenEventChannel();
    }
    return isStarted;
  }

  Future<RTCDetectedFrames?> stop() async {
    final resultRaw = await WebRTC.invokeMethod('stopRecordVideo');
    await _detectionSubscription?.cancel();
    if (resultRaw == null) {
      return null;
    }
    final result = RecorderResult.fromMap(resultRaw);
    // TODO: return duration and file name if no detection
    final detection = _detectionOnVideo;
    detection?.filePath = result.filePath;
    detection?.durationMs = result.durationMs;
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
