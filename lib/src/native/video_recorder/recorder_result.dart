class RecorderResult {
  RecorderResult(this.filePath, this.durationMs);
  factory RecorderResult.fromMap(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);
    final String filePath = map['file'];
    final int durationMs = map['duration'];
    return RecorderResult(filePath, durationMs);
  }

  final String filePath;
  final int durationMs;
}
