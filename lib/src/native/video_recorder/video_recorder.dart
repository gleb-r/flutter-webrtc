import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/src/native/video_recorder/recorder_result.dart';

import '../../../flutter_webrtc.dart';

class VideoRecorder {
  RTCDetectedFrames? _detectionOnVideo;

  late final _eventChannel = EventChannel('FlutterWebRTC/detectionOnVideo');
  StreamSubscription? _detectionSubscription;

  Future<bool> start({
    required String videoPath,
    required String imagePath,
    required bool isLocal,
    required bool enableAudio,
    // required bool directAudio,
  }) async {
    final isStarted = await WebRTC.invokeMethod('startRecordVideo', {
      'videoPath': videoPath,
      'imagePath': imagePath,
      'isLocal': isLocal,
      'enableAudio': enableAudio,
      // 'directAudio': directAudio,
    });
    if (isStarted) {
      _listenEventChannel();
    }
    return isStarted;
  }

  Future<RTCRecordResult> stop() async {
    final resultRaw = await WebRTC.invokeMethod('stopRecordVideo');
    // TODO: listen for write complete event
    await _detectionSubscription?.cancel();
    final result = RecorderResult.fromMap(resultRaw);
    final detection = _detectionOnVideo;
    detection?.durationMs = result.durationMs;
    detection?.frameIntervalMs = result.frameInterval;
    _detectionOnVideo = null;
    return RTCRecordResult.from(result, detection);
  }

  void _listenEventChannel() {
    _detectionSubscription = _eventChannel
        .receiveBroadcastStream()
        .map((event) => DetectionWithTime.fromMap(event))
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
