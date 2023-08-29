import 'dart:async';

import 'package:flutter/services.dart';

import '../../../flutter_webrtc.dart';

abstract class IVideoRecorder {
  Future<bool> start({
    required String videoPath,
    required MediaStream mediaStream,
    required bool enableAudio,
  });

  Future<RTCRecordResult> stop();

  RTCDetectedFrames? detectionOnVideo;

  late final _eventChannel = EventChannel('FlutterWebRTC/detectionOnVideo');
  StreamSubscription? _detectionSubscription;

  void disposeDetection(){
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
