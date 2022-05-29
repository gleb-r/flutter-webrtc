import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/subjects.dart';

import '../../../flutter_webrtc.dart';

class MotionDetection {
  final _detectionSubject = PublishSubject<DetectionResult>();
  StreamSubscription? _subscription;

  Future<bool> start({
    required MediaStreamTrack? videoTrack,
    int detectionLevel = 5,
    int intervalMs = 200,
  }) async {
    if (videoTrack == null) return false;

    try {
      final success = await WebRTC.invokeMethod('startMotionDetection', {
        'trackId': videoTrack.id,
        'level': detectionLevel,
        'interval': intervalMs,
      });
      if (success) {
        _listenEventChannel();
      }
      return success;
    } catch (ex) {
      return false;
    }
  }

  late final _eventChannel = EventChannel('FlutterWebRTC/motionDetection');

  void _listenEventChannel() {
    _subscription ??= _eventChannel
        .receiveBroadcastStream()
        .map(DetectionResult.fromMap)
        .listen(_detectionSubject.add);
  }

  Future<void> stop() async {
    await WebRTC.invokeMethod('stopMotionDetection', {});
  }

  Stream<DetectionResult> get detectionStream => _detectionSubject.stream;

  void dispose() {
    _subscription?.cancel();
    _detectionSubject.close();
  }
}
