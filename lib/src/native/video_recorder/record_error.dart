class RecordError implements Exception {

  RecordError({
    required this.code,
    this.message,
    this.details,
  });

  factory RecordError.fromJson(Map<String, dynamic> json) {
    return RecordError(
      code: json['code'],
      message: json['message'],
      details: json['details'],
    );
  }
  final String code;
  final String? message;
  final Map<String, dynamic>? details;
}
