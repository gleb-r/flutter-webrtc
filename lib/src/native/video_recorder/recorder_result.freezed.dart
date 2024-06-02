// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recorder_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecorderResult _$RecorderResultFromJson(Map<String, dynamic> json) {
  return _RecorderResult.fromJson(json);
}

/// @nodoc
mixin _$RecorderResult {
  @JsonKey(name: 'recordId')
  String get recordId => throw _privateConstructorUsedError;
  @JsonKey(name: 'video')
  String get videoPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration')
  int get durationMs => throw _privateConstructorUsedError;
  @JsonKey(name: 'interval')
  int get frameInterval => throw _privateConstructorUsedError;
  @JsonKey(name: 'rotation')
  int get frameRotation => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecorderResultCopyWith<RecorderResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecorderResultCopyWith<$Res> {
  factory $RecorderResultCopyWith(
          RecorderResult value, $Res Function(RecorderResult) then) =
      _$RecorderResultCopyWithImpl<$Res, RecorderResult>;
  @useResult
  $Res call(
      {@JsonKey(name: 'recordId') String recordId,
      @JsonKey(name: 'video') String videoPath,
      @JsonKey(name: 'duration') int durationMs,
      @JsonKey(name: 'interval') int frameInterval,
      @JsonKey(name: 'rotation') int frameRotation});
}

/// @nodoc
class _$RecorderResultCopyWithImpl<$Res, $Val extends RecorderResult>
    implements $RecorderResultCopyWith<$Res> {
  _$RecorderResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? videoPath = null,
    Object? durationMs = null,
    Object? frameInterval = null,
    Object? frameRotation = null,
  }) {
    return _then(_value.copyWith(
      recordId: null == recordId
          ? _value.recordId
          : recordId // ignore: cast_nullable_to_non_nullable
              as String,
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      frameInterval: null == frameInterval
          ? _value.frameInterval
          : frameInterval // ignore: cast_nullable_to_non_nullable
              as int,
      frameRotation: null == frameRotation
          ? _value.frameRotation
          : frameRotation // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecorderResultImplCopyWith<$Res>
    implements $RecorderResultCopyWith<$Res> {
  factory _$$RecorderResultImplCopyWith(_$RecorderResultImpl value,
          $Res Function(_$RecorderResultImpl) then) =
      __$$RecorderResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'recordId') String recordId,
      @JsonKey(name: 'video') String videoPath,
      @JsonKey(name: 'duration') int durationMs,
      @JsonKey(name: 'interval') int frameInterval,
      @JsonKey(name: 'rotation') int frameRotation});
}

/// @nodoc
class __$$RecorderResultImplCopyWithImpl<$Res>
    extends _$RecorderResultCopyWithImpl<$Res, _$RecorderResultImpl>
    implements _$$RecorderResultImplCopyWith<$Res> {
  __$$RecorderResultImplCopyWithImpl(
      _$RecorderResultImpl _value, $Res Function(_$RecorderResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? videoPath = null,
    Object? durationMs = null,
    Object? frameInterval = null,
    Object? frameRotation = null,
  }) {
    return _then(_$RecorderResultImpl(
      recordId: null == recordId
          ? _value.recordId
          : recordId // ignore: cast_nullable_to_non_nullable
              as String,
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      frameInterval: null == frameInterval
          ? _value.frameInterval
          : frameInterval // ignore: cast_nullable_to_non_nullable
              as int,
      frameRotation: null == frameRotation
          ? _value.frameRotation
          : frameRotation // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecorderResultImpl implements _RecorderResult {
  const _$RecorderResultImpl(
      {@JsonKey(name: 'recordId') required this.recordId,
      @JsonKey(name: 'video') required this.videoPath,
      @JsonKey(name: 'duration') required this.durationMs,
      @JsonKey(name: 'interval') required this.frameInterval,
      @JsonKey(name: 'rotation') required this.frameRotation});

  factory _$RecorderResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecorderResultImplFromJson(json);

  @override
  @JsonKey(name: 'recordId')
  final String recordId;
  @override
  @JsonKey(name: 'video')
  final String videoPath;
  @override
  @JsonKey(name: 'duration')
  final int durationMs;
  @override
  @JsonKey(name: 'interval')
  final int frameInterval;
  @override
  @JsonKey(name: 'rotation')
  final int frameRotation;

  @override
  String toString() {
    return 'RecorderResult(recordId: $recordId, videoPath: $videoPath, durationMs: $durationMs, frameInterval: $frameInterval, frameRotation: $frameRotation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecorderResultImpl &&
            (identical(other.recordId, recordId) ||
                other.recordId == recordId) &&
            (identical(other.videoPath, videoPath) ||
                other.videoPath == videoPath) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.frameInterval, frameInterval) ||
                other.frameInterval == frameInterval) &&
            (identical(other.frameRotation, frameRotation) ||
                other.frameRotation == frameRotation));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recordId, videoPath, durationMs,
      frameInterval, frameRotation);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecorderResultImplCopyWith<_$RecorderResultImpl> get copyWith =>
      __$$RecorderResultImplCopyWithImpl<_$RecorderResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecorderResultImplToJson(
      this,
    );
  }
}

abstract class _RecorderResult implements RecorderResult {
  const factory _RecorderResult(
          {@JsonKey(name: 'recordId') required final String recordId,
          @JsonKey(name: 'video') required final String videoPath,
          @JsonKey(name: 'duration') required final int durationMs,
          @JsonKey(name: 'interval') required final int frameInterval,
          @JsonKey(name: 'rotation') required final int frameRotation}) =
      _$RecorderResultImpl;

  factory _RecorderResult.fromJson(Map<String, dynamic> json) =
      _$RecorderResultImpl.fromJson;

  @override
  @JsonKey(name: 'recordId')
  String get recordId;
  @override
  @JsonKey(name: 'video')
  String get videoPath;
  @override
  @JsonKey(name: 'duration')
  int get durationMs;
  @override
  @JsonKey(name: 'interval')
  int get frameInterval;
  @override
  @JsonKey(name: 'rotation')
  int get frameRotation;
  @override
  @JsonKey(ignore: true)
  _$$RecorderResultImplCopyWith<_$RecorderResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
