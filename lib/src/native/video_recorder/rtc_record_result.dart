// ignore_for_file: invalid_annotation_target
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rtc_record_result.freezed.dart';
part 'rtc_record_result.g.dart';

@freezed
class RTCRecordResult with _$RTCRecordResult {
  @JsonSerializable(explicitToJson: true)
  factory RTCRecordResult({
    @JsonKey(name: "recordId") required String recordId,
    @JsonKey(name: "video") required String videoPath,
    @JsonKey(name: "detection") required DetectionData? detection,
    @JsonKey(name: "duration") required int durationMs,
    @JsonKey(name: "interval") required int frameInterval,
    @JsonKey(name: "rotation") required int frameRotation,
  }) = _RTCRecordResult;

  const RTCRecordResult._();

  factory RTCRecordResult.fromJson(Map<String, dynamic> json) =>
      _$RTCRecordResultFromJson(json);
}

@freezed
class DetectionData with _$DetectionData {
  factory DetectionData({
    @JsonKey(name: "f") required Map<String, List<dynamic>> rawFrames,
    @JsonKey(name: "a") required double aspect,
    @JsonKey(name: "x") required int xSqCount,
    @JsonKey(name: "y") required int ySqCount,
  }) = _RTCDetectedFrames;

  const DetectionData._();

  factory DetectionData.fromJson(Map<String, dynamic> json) =>
      _$DetectionDataFromJson(json);

  factory DetectionData.fromString(String serialized) =>
      DetectionData.fromJson(jsonDecode(serialized));

  String serialized() => jsonEncode(toJson());
}
