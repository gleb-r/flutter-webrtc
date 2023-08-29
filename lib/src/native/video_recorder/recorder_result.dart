class RecorderResult {
  RecorderResult({
    required this.videoPath,
    required this.durationMs,
    required this.frameInterval,
    required this.frameRotation,
  });

  factory RecorderResult.fromMap(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final String videoPath = map['video'];
    final int durationMs = map['duration'];
    final int frameInterval = map['interval'];
    final int frameRotation = map['rotation'];
    return RecorderResult(
      videoPath: videoPath,
      durationMs: durationMs,
      frameInterval: frameInterval,
      frameRotation: frameRotation,
    );
  }

  final String videoPath;
  final int durationMs;
  final int frameInterval;
  final int frameRotation;
}
