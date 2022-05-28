import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flutter_webrtc.dart';

class MotionDetection {
  Future<void> start(MediaStreamTrack? videoTrack) async {
    if (videoTrack == null) return;

    await WebRTC.invokeMethod('startMotionDetection', {
      'trackId': videoTrack.id,
    });
  }

  Future<void> stop() async {
    await WebRTC.invokeMethod('stopMotionDetection', {});
  }

  Stream<List<Square>> get detectionStream =>
      EventChannel('FlutterWebRTC/motionDetection')
          .receiveBroadcastStream()
          .map(parseEventSq);

  List<Rect> parseEvent(dynamic event) {
    final map = LinkedHashMap<String, dynamic>.from(event as Map);
    final bool isDetected = map['detected'];
    if (!isDetected) return [];
    final List<dynamic> rectList = map['rect'];
    return rectList.map(parseRect).toList();
  }

  List<Square> parseEventSq(dynamic event) {
    final map = LinkedHashMap<String, dynamic>.from(event as Map);
    final bool isDetected = map['detected'];
    if (!isDetected) return [];
    final List<dynamic> rectList = map['rect'];
    return rectList.map(parseSquare).toList();
  }

  Rect parseRect(dynamic object) {
    final map = LinkedHashMap<String, dynamic>.from(object);
    final double left = map['l'];
    final double top = map['t'];
    final double right = map['r'];
    final double bottom = map['b'];

    return Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );
  }

  Square parseSquare(dynamic object) {
    final map = LinkedHashMap<String, dynamic>.from(object);
    final double left = map['l'];
    final double top = map['t'];
    final double right = map['r'];
    final double bottom = map['b'];
    final int color = map['c'];

    final rect = Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );
    return Square(rect, color);
  }
}

class Square {
  Square(this.rect, this.color);

  final Rect rect;
  final int color;
}
