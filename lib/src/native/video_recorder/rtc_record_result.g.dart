// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rtc_record_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RTCRecordResultImpl _$$RTCRecordResultImplFromJson(
        Map<String, dynamic> json) =>
    _$RTCRecordResultImpl(
      recordId: json['recordId'] as String,
      videoPath: json['video'] as String,
      detection: json['detection'] == null
          ? null
          : DetectionData.fromJson(json['detection'] as Map<String, dynamic>),
      durationMs: (json['duration'] as num).toInt(),
      frameInterval: (json['interval'] as num).toInt(),
      frameRotation: (json['rotation'] as num).toInt(),
    );

Map<String, dynamic> _$$RTCRecordResultImplToJson(
        _$RTCRecordResultImpl instance) =>
    <String, dynamic>{
      'recordId': instance.recordId,
      'video': instance.videoPath,
      'detection': instance.detection?.toJson(),
      'duration': instance.durationMs,
      'interval': instance.frameInterval,
      'rotation': instance.frameRotation,
    };

_$RTCDetectedFramesImpl _$$RTCDetectedFramesImplFromJson(
        Map<String, dynamic> json) =>
    _$RTCDetectedFramesImpl(
      rawFrames: (json['f'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as List<dynamic>),
      ),
      aspect: (json['a'] as num).toDouble(),
      xSqCount: (json['x'] as num).toInt(),
      ySqCount: (json['y'] as num).toInt(),
    );

Map<String, dynamic> _$$RTCDetectedFramesImplToJson(
        _$RTCDetectedFramesImpl instance) =>
    <String, dynamic>{
      'f': instance.rawFrames,
      'a': instance.aspect,
      'x': instance.xSqCount,
      'y': instance.ySqCount,
    };
