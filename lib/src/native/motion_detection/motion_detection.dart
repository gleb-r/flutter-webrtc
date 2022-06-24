import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/subjects.dart';

import '../../../flutter_webrtc.dart';

class MotionDetection {
  final _detectionSubject = PublishSubject<DetectionFrame>();
  StreamSubscription? _subscription;

  Future<void> setDetectionData(DetectionRequest request) async {
    await WebRTC.invokeMethod('motionDetection', request.toMap());
    if (_subscription == null) {
      _listenEventChannel();
    }
    if (!request.enabled) {
      _detectionSubject.add(DetectionFrame.empty());
    }
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/motionDetection');

  void _listenEventChannel() {
    _subscription = _eventChannel
        .receiveBroadcastStream()
        .map(DetectionFrame.fromMap)
        .listen(_detectionSubject.add);
  }

  Stream<DetectionFrame> get detectionStream => _detectionSubject.stream;

  void dispose() {
    _subscription?.cancel();
    _detectionSubject.close();
  }
}
