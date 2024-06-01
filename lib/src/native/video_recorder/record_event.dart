import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_event.freezed.dart';
part 'record_event.g.dart';

@freezed
class RecordEvent with _$RecordEvent {
  const factory RecordEvent({
    required RecordEventType type,
    Map<String, dynamic>? data,
  }) = _RecordEvent;

  factory RecordEvent.fromJson(Map<String, dynamic> json) =>
      _$RecordEventFromJson(json);
}

enum RecordEventType {
  @JsonValue('idle')
  idle,
  @JsonValue('starting')
  starting,
  @JsonValue('recording')
  recording,
  @JsonValue('stop')
  stop,
  @JsonValue('result')
  result,
  @JsonValue('error')
  error,
}

