import 'dart:collection';
import 'dart:convert';
import 'package:flutter_webrtc/src/native/video_recorder/recorder_result.dart';

class RTCRecordResult {
  RTCRecordResult({
    required this.recordId,
    required this.videoPath,
    required this.detectedFrames,
    required this.frameRotation,
    required this.frameInterval,
    required this.durationMs,
  });

  factory RTCRecordResult.from(
      RecorderResult result, RTCDetectedFrames? frames) {
    return RTCRecordResult(
      recordId: result.recordId,
      videoPath: result.videoPath,
      detectedFrames: frames,
      frameRotation: result.frameRotation,
      frameInterval: result.frameInterval,
      durationMs: result.durationMs,
    );
  }

  final String recordId;
  final String videoPath;
  final RTCDetectedFrames? detectedFrames;
  final int durationMs;
  final int frameInterval;
  final int frameRotation;
}

class RTCDetectedFrames {
  RTCDetectedFrames({
    required this.rawFrames,
    required this.aspect,
    required this.xSqCount,
    required this.ySqCount,
    this.frameIntervalMs = 0,
    this.durationMs = 0,
  });

  factory RTCDetectedFrames.init(DetectionWithTime firstDetection) {
    return RTCDetectedFrames(
      rawFrames: {firstDetection.frameIndex.toString(): firstDetection.squares},
      aspect: firstDetection.aspect,
      xSqCount: firstDetection.xSqCount,
      ySqCount: firstDetection.ySqCount,
    );
  }

  factory RTCDetectedFrames.fromString(String serialized) =>
      RTCDetectedFrames.fromMap(jsonDecode(serialized));

  factory RTCDetectedFrames.fromMap(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final double aspect = map['a'];
    final int x = map['x'];
    final int y = map['y'];
    final int frameTime = map['ft'];
    final duration = map['d'];
    final frames = Map<String, List<dynamic>>.from(map['frames']);
    return RTCDetectedFrames(
      rawFrames: frames,
      aspect: aspect,
      xSqCount: x,
      ySqCount: y,
      frameIntervalMs: frameTime,
      durationMs: duration,
    );
  }

  final Map<String, List<dynamic>> rawFrames;
  final double aspect;
  final int xSqCount;
  final int ySqCount;
  int frameIntervalMs;
  int durationMs;

  void addFrame(DetectionWithTime frame) {
    if (
// aspect != frame.aspect ||
        xSqCount != xSqCount || ySqCount != ySqCount) {
      throw Exception(
          'Detection frame size changed, current: $aspect, new:${frame.aspect}');
    }
    rawFrames[frame.frameIndex.toString()] = frame.squares;
  }

  Map<String, dynamic> toMap() {
    return {
      'a': aspect,
      'x': xSqCount,
      'y': ySqCount,
      'd': durationMs,
      'ft': frameIntervalMs,
      'frames': rawFrames,
    };
  }

  String serialized() => jsonEncode(toMap());
}

class DetectionWithTime {
  DetectionWithTime({
    required this.squares,
    required this.frameIndex,
    required this.aspect,
    required this.xSqCount,
    required this.ySqCount,
  });

  factory DetectionWithTime.fromMap(dynamic event) {
    final map = LinkedHashMap<String, dynamic>.from(event as Map);
    final int time = map['i'];
    final List<dynamic> list = map['l'];

    final double aspect = map['a'];
    final int xSqCount = map['x'];
    final int ySqCount = map['y'];
    return DetectionWithTime(
      squares: list,
      frameIndex: time,
      aspect: aspect,
      xSqCount: xSqCount,
      ySqCount: ySqCount,
    );
  }

  final List<dynamic> squares;
  final int frameIndex;
  final double aspect;
  final int xSqCount;
  final int ySqCount;
}