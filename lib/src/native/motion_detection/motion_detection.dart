import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/subjects.dart';

import '../../../flutter_webrtc.dart';

class MotionDetection {
  final _detectionSubject = PublishSubject<DetectionFrame>();
  StreamSubscription? _subscription;
  bool isPaused = false;

  Future<void> setDetectionData(DetectionRequest request) async {
    await WebRTC.invokeMethod('motionDetection', request.toMap());
    if (_subscription == null && request.enabled) {
      _listenEventChannel();
    }
    if (!request.enabled) {
      _detectionSubject.add(DetectionFrame.empty());
    }
  }

  void pause(Duration duration) {
    isPaused = true;
    _detectionSubject.add(DetectionFrame.empty());
    Future.delayed(duration).then((_) => isPaused = false);
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/motionDetection');

  void _listenEventChannel() {
    _subscription = _eventChannel
        .receiveBroadcastStream()
        .map((event) => DetectionFrame.fromMap(event))
        .listen((detection) {
      if (!isPaused) {
        _detectionSubject.add(detection);
      }
    });
  }

  Stream<DetectionFrame> get detectionStream => _detectionSubject.stream;

  void dispose() {
    final disableRequest = DetectionRequest(false, 2);
    WebRTC.invokeMethod('motionDetection', disableRequest.toMap());
    _subscription?.cancel();
  }
}