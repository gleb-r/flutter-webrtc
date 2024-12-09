import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../../flutter_webrtc.dart';

class NightVision {
  NightVision() {
    _listenEventChannel();
  }

  final _exposureOffsetSubject = BehaviorSubject<ExposureAnalyzerResult>();
  late final _eventChannel = EventChannel('FlutterWebRTC/expositionOffset');
  StreamSubscription? _subscription;

  Future<void> setCustomExposure({
    required MediaStreamTrackNative videoTrack,
    required ExposureParams params,
  }) {
    switch (params) {
      case ExposureAuto():
        return videoTrack.setCustomExposure(
          enable: false,
          ultraBrightness: false,
          durationMs: 0,
          iso: 0,
        );
      case final ExposureCustom custom:
        return videoTrack.setCustomExposure(
          enable: true,
          ultraBrightness: false,
          durationMs: custom.durationMs,
          iso: custom.iso,
        );

      case final ExposureUltra ultra:
        return videoTrack.setCustomExposure(
          enable: true,
          ultraBrightness: true,
          durationMs: ultra.durationMs,
          iso: ultra.iso,
        );
    }
  }

  void _listenEventChannel() async {
    await Future.delayed(Duration(seconds: 1));
    _subscription = _eventChannel
        .receiveBroadcastStream()
        .mapNotNull(_getResultFromEvent)
        .listen(_exposureOffsetSubject.add);
  }

  Stream<ExposureAnalyzerResult> get exposureOffsetStream =>
      _exposureOffsetSubject.stream;

  ExposureAnalyzerResult? _getResultFromEvent(dynamic event) {
    if (event != null && event is Map) {
      return ExposureAnalyzerResult.fromMap(event.cast<String, dynamic>());
    } else {
      debugPrint(
          'Invalid expositionOffset: $event, type: ${event.runtimeType}');
      return null;
    }
  }

  void dispose() {
    final disableRequest = false;
    WebRTC.invokeMethod('expositionAnalyzer', disableRequest);
    _subscription?.cancel();
    _exposureOffsetSubject.close();
  }
}

sealed class ExposureParams {
  @override
  String toString() {
    if (this is ExposureCustom) {
      final c = this as ExposureCustom;
      return "Custom(${c.durationMs}ms, iso:${c.iso})";
    }
    if (this is ExposureUltra) {
      final u = this as ExposureUltra;
      return "Ultra(${u.durationMs}ms, iso:${u.iso})";
    }
    if (this is ExposureAuto) {
      return "ExposureAuto()";
    }
    return "undef state";
  }
}

class ExposureAuto extends ExposureParams {}

class ExposureCustom extends ExposureParams {
  ExposureCustom({
    required this.durationMs,
    required this.iso,
  });

  final int durationMs;
  final int iso;
}

class ExposureUltra extends ExposureParams {
  ExposureUltra({
    required this.durationMs,
    required this.iso,
  });

  final int durationMs;
  final int iso;
}

class ExposureAnalyzerResult {
  ExposureAnalyzerResult({
    required this.isCustomExposure,
    required this.isUltraBrightness,
    required this.offset,
    required this.currentDurationMs,
    required this.currentISO,
    required this.maxDurationMs,
    required this.maxAutoDurationMs,
    required this.maxIso,
    required this.maxAutoISO,
  });

  factory ExposureAnalyzerResult.fromMap(Map<String, dynamic> map) {
    return ExposureAnalyzerResult(
      isCustomExposure: map['isCustomExposureOn'],
      isUltraBrightness: map['isUltraBrightness'],
      offset: map['exposureOffset'],
      currentDurationMs: map['currentDurationMs'],
      currentISO: map['currentISO'],
      maxDurationMs: map['maxDurationMs'],
      maxAutoDurationMs: map['maxAutoDurationMs'],
      maxIso: map['maxISO'],
      maxAutoISO: map['maxAutoISO'],
    );
  }

  final bool isCustomExposure;
  final bool isUltraBrightness;
  final double offset;
  final int currentDurationMs;
  final int currentISO;

  // max exposure duration from camera capabilities
  final int maxDurationMs;

  // max exposure duration in auto mode
  final int maxAutoDurationMs;

  // max ISO from camera capabilities
  final int maxIso;

  // max ISO in auto mode
  final int maxAutoISO;

  String get level {
    if (isCustomExposure) {
      if (isUltraBrightness) {
        return "ultra";
      } else {
        return "custom";
      }
    } else {
      return "auto";
    }
  }
}
