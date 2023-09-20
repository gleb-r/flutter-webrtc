class RecorderResult {
  RecorderResult({
    required this.recordId,
    required this.videoPath,
    required this.durationMs,
    required this.frameInterval,
    required this.frameRotation,
  });

  factory RecorderResult.fromMap(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final String recordId = map['recordId'];
    final String videoPath = map['video'];
    final int durationMs = map['duration'];
    final int frameInterval = map['interval'];
    final int frameRotation = map['rotation'];
    return RecorderResult(
      recordId: recordId,
      videoPath: videoPath,
      durationMs: durationMs,
      frameInterval: frameInterval,
      frameRotation: frameRotation,
    );
  }

  final String recordId;
  final String videoPath;
  final int durationMs;
  final int frameInterval;
  final int frameRotation;
}