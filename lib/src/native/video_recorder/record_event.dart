import 'dart:convert';

class RecordEvent {
  RecordEvent({
    required this.type,
    this.data,
  });

  factory RecordEvent.fromMap(Map<Object?, Object?> map) =>
      RecordEvent.fromJson(jsonDecode(jsonEncode(map)));

  factory RecordEvent.fromJson(Map<String, dynamic> json) {
    return RecordEvent(
      type: RecordEventType.fromString(json['type']),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  final RecordEventType type;
  final Map<String, dynamic>? data;
}

enum RecordEventType {
  idle,
  starting,
  recording,
  stop,
  result,
  error,
  ;

  static RecordEventType fromString(String value) =>
      RecordEventType.values.firstWhere((element) => element.name == value);
}
