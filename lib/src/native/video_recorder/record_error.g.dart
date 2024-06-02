// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecordErrorImpl _$$RecordErrorImplFromJson(Map<String, dynamic> json) =>
    _$RecordErrorImpl(
      code: json['code'] as String,
      message: json['message'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$RecordErrorImplToJson(_$RecordErrorImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };
