// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recorder_result.freezed.dart';
part 'recorder_result.g.dart';

@freezed
class RecorderResult with _$RecorderResult {

  const factory RecorderResult({
    @JsonKey(name: 'recordId') required String recordId,
    @JsonKey(name: 'video') required String videoPath,
    @JsonKey(name: 'duration') required int durationMs,
    @JsonKey(name:'interval' )required int frameInterval,
    @JsonKey(name: 'rotation')required int frameRotation,
  }) = _RecorderResult;

  factory RecorderResult.fromJson(Map<String, dynamic> json) => _$RecorderResultFromJson(json);
 }
