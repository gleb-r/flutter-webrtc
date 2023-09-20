import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/src/native/video_recorder/recorder_result.dart';
import 'package:path_provider/path_provider.dart';

import '../../../flutter_webrtc.dart';
import 'i_video_recorder.dart';

class VideoRecorder extends IVideoRecorder {
  @override
  Future<bool> start({
    required String dirPath,
    required MediaStream mediaStream,
    required bool enableAudio,
    // required bool directAudio,
  }) async {
    final isStarted = await WebRTC.invokeMethod('startRecordVideo', {
      'dirPath': dirPath,
      'streamId': mediaStream.id,
      'enableAudio': enableAudio,
      // 'directAudio': directAudio,
    });
    if (isStarted) {
      listenEventChannel();
    }
    return isStarted;
  }

  @override
  Future<RTCRecordResult> stop() async {
    disposeDetection();
    final resultRaw = await WebRTC.invokeMethod('stopRecordVideo');
    // TODO: listen for write complete event
    final result = RecorderResult.fromMap(resultRaw);
    final detection = detectionOnVideo;
    detection?.durationMs = result.durationMs;
    detection?.frameIntervalMs = result.frameInterval;
    detectionOnVideo = null;
    return RTCRecordResult.from(result, detection);
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/detectionOnVideo');
  StreamSubscription? _detectionSubscription;

  void disposeDetection() {
    _detectionSubscription?.cancel();
  }

  void listenEventChannel() {
    _detectionSubscription = _eventChannel
        .receiveBroadcastStream()
        .map((event) => DetectionWithTime.fromMap(event))
        .listen((detection) {
      if (detectionOnVideo == null) {
        detectionOnVideo = RTCDetectedFrames.init(detection);
      } else {
        detectionOnVideo?.addFrame(detection);
      }
    });
  }
}