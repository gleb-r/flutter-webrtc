import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_error.freezed.dart';
part 'record_error.g.dart';

@freezed
class RecordError with _$RecordError implements Exception {
  const factory RecordError({
    required String code,
    String? message,
    Map<String, dynamic>? details,
  }) = _RecordError;

  factory RecordError.fromJson(Map<String, dynamic> json) =>
      _$RecordErrorFromJson(json);

}