// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recorder_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecorderResultImpl _$$RecorderResultImplFromJson(Map<String, dynamic> json) =>
    _$RecorderResultImpl(
      recordId: json['recordId'] as String,
      videoPath: json['video'] as String,
      durationMs: (json['duration'] as num).toInt(),
      frameInterval: (json['interval'] as num).toInt(),
      frameRotation: (json['rotation'] as num).toInt(),
    );

Map<String, dynamic> _$$RecorderResultImplToJson(
        _$RecorderResultImpl instance) =>
    <String, dynamic>{
      'recordId': instance.recordId,
      'video': instance.videoPath,
      'duration': instance.durationMs,
      'interval': instance.frameInterval,
      'rotation': instance.frameRotation,
    };
