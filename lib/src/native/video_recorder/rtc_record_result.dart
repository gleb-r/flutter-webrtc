import 'dart:convert';

class RTCRecordResult {
  RTCRecordResult({
    required this.recordId,
    required this.videoPath,
    required this.detection,
    required this.durationMs,
    required this.frameRotation,
  });

  factory RTCRecordResult.fromJson(Map<String, dynamic> json) {
    return RTCRecordResult(
      recordId: json['recordId'],
      videoPath: json['video'],
      detection: json['detection'] != null
          ? DetectionData.fromJson(json['detection'])
          : null,
      durationMs: json['duration'],
      frameRotation: json['rotation'],
    );
  }

  final String recordId;
  final String videoPath;
  final DetectionData? detection;
  final int durationMs;
  final int frameRotation;
}

class DetectionData {
  DetectionData({
    required this.rawFrames,
    required this.aspect,
    required this.xSqCount,
    required this.ySqCount,
    required this.frameIntervalMs,
    required this.durationMs,
  });

  factory DetectionData.fromString(String serialized) =>
      DetectionData.fromJson(jsonDecode(serialized));

  factory DetectionData.fromJson(Map<String, dynamic> json) {
    return DetectionData(
      rawFrames: Map<String, List<String>>.of(json['f']),
      aspect: json['a'],
      xSqCount: json['x'],
      ySqCount: json['y'],
      frameIntervalMs: json['i'],
      durationMs: json['d'],
    );
  }

  Map<String, dynamic> toJson() => {
        'f': rawFrames,
        'a': aspect,
        'x': xSqCount,
        'y': ySqCount,
        'i': frameIntervalMs,
        'd': durationMs,
      };

  final Map<String, List<String>> rawFrames;
  final double aspect;
  final int xSqCount;
  final int ySqCount;
  final int frameIntervalMs;
  int durationMs = 0;

  String serialized() => jsonEncode(toJson());
}
