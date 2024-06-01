// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecordEventImpl _$$RecordEventImplFromJson(Map<String, dynamic> json) =>
    _$RecordEventImpl(
      type: $enumDecode(_$RecordEventTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$RecordEventImplToJson(_$RecordEventImpl instance) =>
    <String, dynamic>{
      'type': _$RecordEventTypeEnumMap[instance.type]!,
      'data': instance.data,
    };

const _$RecordEventTypeEnumMap = {
  RecordEventType.idle: 'idle',
  RecordEventType.starting: 'starting',
  RecordEventType.recording: 'recording',
  RecordEventType.stop: 'stop',
  RecordEventType.result: 'result',
  RecordEventType.error: 'error',
};
