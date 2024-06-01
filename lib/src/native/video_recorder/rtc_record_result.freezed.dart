// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rtc_record_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RTCRecordResult _$RTCRecordResultFromJson(Map<String, dynamic> json) {
  return _RTCRecordResult.fromJson(json);
}

/// @nodoc
mixin _$RTCRecordResult {
  @JsonKey(name: "recordId")
  String get recordId => throw _privateConstructorUsedError;
  @JsonKey(name: "video")
  String get videoPath => throw _privateConstructorUsedError;
  @JsonKey(name: "detection")
  DetectionData? get detection => throw _privateConstructorUsedError;
  @JsonKey(name: "duration")
  int get durationMs => throw _privateConstructorUsedError;
  @JsonKey(name: "interval")
  int get frameInterval => throw _privateConstructorUsedError;
  @JsonKey(name: "rotation")
  int get frameRotation => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RTCRecordResultCopyWith<RTCRecordResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RTCRecordResultCopyWith<$Res> {
  factory $RTCRecordResultCopyWith(
          RTCRecordResult value, $Res Function(RTCRecordResult) then) =
      _$RTCRecordResultCopyWithImpl<$Res, RTCRecordResult>;
  @useResult
  $Res call(
      {@JsonKey(name: "recordId") String recordId,
      @JsonKey(name: "video") String videoPath,
      @JsonKey(name: "detection") DetectionData? detection,
      @JsonKey(name: "duration") int durationMs,
      @JsonKey(name: "interval") int frameInterval,
      @JsonKey(name: "rotation") int frameRotation});

  $DetectionDataCopyWith<$Res>? get detection;
}

/// @nodoc
class _$RTCRecordResultCopyWithImpl<$Res, $Val extends RTCRecordResult>
    implements $RTCRecordResultCopyWith<$Res> {
  _$RTCRecordResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? videoPath = null,
    Object? detection = freezed,
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
      detection: freezed == detection
          ? _value.detection
          : detection // ignore: cast_nullable_to_non_nullable
              as DetectionData?,
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

  @override
  @pragma('vm:prefer-inline')
  $DetectionDataCopyWith<$Res>? get detection {
    if (_value.detection == null) {
      return null;
    }

    return $DetectionDataCopyWith<$Res>(_value.detection!, (value) {
      return _then(_value.copyWith(detection: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RTCRecordResultImplCopyWith<$Res>
    implements $RTCRecordResultCopyWith<$Res> {
  factory _$$RTCRecordResultImplCopyWith(_$RTCRecordResultImpl value,
          $Res Function(_$RTCRecordResultImpl) then) =
      __$$RTCRecordResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: "recordId") String recordId,
      @JsonKey(name: "video") String videoPath,
      @JsonKey(name: "detection") DetectionData? detection,
      @JsonKey(name: "duration") int durationMs,
      @JsonKey(name: "interval") int frameInterval,
      @JsonKey(name: "rotation") int frameRotation});

  @override
  $DetectionDataCopyWith<$Res>? get detection;
}

/// @nodoc
class __$$RTCRecordResultImplCopyWithImpl<$Res>
    extends _$RTCRecordResultCopyWithImpl<$Res, _$RTCRecordResultImpl>
    implements _$$RTCRecordResultImplCopyWith<$Res> {
  __$$RTCRecordResultImplCopyWithImpl(
      _$RTCRecordResultImpl _value, $Res Function(_$RTCRecordResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? videoPath = null,
    Object? detection = freezed,
    Object? durationMs = null,
    Object? frameInterval = null,
    Object? frameRotation = null,
  }) {
    return _then(_$RTCRecordResultImpl(
      recordId: null == recordId
          ? _value.recordId
          : recordId // ignore: cast_nullable_to_non_nullable
              as String,
      videoPath: null == videoPath
          ? _value.videoPath
          : videoPath // ignore: cast_nullable_to_non_nullable
              as String,
      detection: freezed == detection
          ? _value.detection
          : detection // ignore: cast_nullable_to_non_nullable
              as DetectionData?,
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

@JsonSerializable(explicitToJson: true)
class _$RTCRecordResultImpl extends _RTCRecordResult {
  _$RTCRecordResultImpl(
      {@JsonKey(name: "recordId") required this.recordId,
      @JsonKey(name: "video") required this.videoPath,
      @JsonKey(name: "detection") required this.detection,
      @JsonKey(name: "duration") required this.durationMs,
      @JsonKey(name: "interval") required this.frameInterval,
      @JsonKey(name: "rotation") required this.frameRotation})
      : super._();

  factory _$RTCRecordResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$RTCRecordResultImplFromJson(json);

  @override
  @JsonKey(name: "recordId")
  final String recordId;
  @override
  @JsonKey(name: "video")
  final String videoPath;
  @override
  @JsonKey(name: "detection")
  final DetectionData? detection;
  @override
  @JsonKey(name: "duration")
  final int durationMs;
  @override
  @JsonKey(name: "interval")
  final int frameInterval;
  @override
  @JsonKey(name: "rotation")
  final int frameRotation;

  @override
  String toString() {
    return 'RTCRecordResult(recordId: $recordId, videoPath: $videoPath, detection: $detection, durationMs: $durationMs, frameInterval: $frameInterval, frameRotation: $frameRotation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RTCRecordResultImpl &&
            (identical(other.recordId, recordId) ||
                other.recordId == recordId) &&
            (identical(other.videoPath, videoPath) ||
                other.videoPath == videoPath) &&
            (identical(other.detection, detection) ||
                other.detection == detection) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.frameInterval, frameInterval) ||
                other.frameInterval == frameInterval) &&
            (identical(other.frameRotation, frameRotation) ||
                other.frameRotation == frameRotation));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recordId, videoPath, detection,
      durationMs, frameInterval, frameRotation);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RTCRecordResultImplCopyWith<_$RTCRecordResultImpl> get copyWith =>
      __$$RTCRecordResultImplCopyWithImpl<_$RTCRecordResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RTCRecordResultImplToJson(
      this,
    );
  }
}

abstract class _RTCRecordResult extends RTCRecordResult {
  factory _RTCRecordResult(
          {@JsonKey(name: "recordId") required final String recordId,
          @JsonKey(name: "video") required final String videoPath,
          @JsonKey(name: "detection") required final DetectionData? detection,
          @JsonKey(name: "duration") required final int durationMs,
          @JsonKey(name: "interval") required final int frameInterval,
          @JsonKey(name: "rotation") required final int frameRotation}) =
      _$RTCRecordResultImpl;
  _RTCRecordResult._() : super._();

  factory _RTCRecordResult.fromJson(Map<String, dynamic> json) =
      _$RTCRecordResultImpl.fromJson;

  @override
  @JsonKey(name: "recordId")
  String get recordId;
  @override
  @JsonKey(name: "video")
  String get videoPath;
  @override
  @JsonKey(name: "detection")
  DetectionData? get detection;
  @override
  @JsonKey(name: "duration")
  int get durationMs;
  @override
  @JsonKey(name: "interval")
  int get frameInterval;
  @override
  @JsonKey(name: "rotation")
  int get frameRotation;
  @override
  @JsonKey(ignore: true)
  _$$RTCRecordResultImplCopyWith<_$RTCRecordResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectionData _$DetectionDataFromJson(Map<String, dynamic> json) {
  return _RTCDetectedFrames.fromJson(json);
}

/// @nodoc
mixin _$DetectionData {
  @JsonKey(name: "f")
  Map<String, List<dynamic>> get rawFrames =>
      throw _privateConstructorUsedError;
  @JsonKey(name: "a")
  double get aspect => throw _privateConstructorUsedError;
  @JsonKey(name: "x")
  int get xSqCount => throw _privateConstructorUsedError;
  @JsonKey(name: "y")
  int get ySqCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DetectionDataCopyWith<DetectionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionDataCopyWith<$Res> {
  factory $DetectionDataCopyWith(
          DetectionData value, $Res Function(DetectionData) then) =
      _$DetectionDataCopyWithImpl<$Res, DetectionData>;
  @useResult
  $Res call(
      {@JsonKey(name: "f") Map<String, List<dynamic>> rawFrames,
      @JsonKey(name: "a") double aspect,
      @JsonKey(name: "x") int xSqCount,
      @JsonKey(name: "y") int ySqCount});
}

/// @nodoc
class _$DetectionDataCopyWithImpl<$Res, $Val extends DetectionData>
    implements $DetectionDataCopyWith<$Res> {
  _$DetectionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rawFrames = null,
    Object? aspect = null,
    Object? xSqCount = null,
    Object? ySqCount = null,
  }) {
    return _then(_value.copyWith(
      rawFrames: null == rawFrames
          ? _value.rawFrames
          : rawFrames // ignore: cast_nullable_to_non_nullable
              as Map<String, List<dynamic>>,
      aspect: null == aspect
          ? _value.aspect
          : aspect // ignore: cast_nullable_to_non_nullable
              as double,
      xSqCount: null == xSqCount
          ? _value.xSqCount
          : xSqCount // ignore: cast_nullable_to_non_nullable
              as int,
      ySqCount: null == ySqCount
          ? _value.ySqCount
          : ySqCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RTCDetectedFramesImplCopyWith<$Res>
    implements $DetectionDataCopyWith<$Res> {
  factory _$$RTCDetectedFramesImplCopyWith(_$RTCDetectedFramesImpl value,
          $Res Function(_$RTCDetectedFramesImpl) then) =
      __$$RTCDetectedFramesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: "f") Map<String, List<dynamic>> rawFrames,
      @JsonKey(name: "a") double aspect,
      @JsonKey(name: "x") int xSqCount,
      @JsonKey(name: "y") int ySqCount});
}

/// @nodoc
class __$$RTCDetectedFramesImplCopyWithImpl<$Res>
    extends _$DetectionDataCopyWithImpl<$Res, _$RTCDetectedFramesImpl>
    implements _$$RTCDetectedFramesImplCopyWith<$Res> {
  __$$RTCDetectedFramesImplCopyWithImpl(_$RTCDetectedFramesImpl _value,
      $Res Function(_$RTCDetectedFramesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rawFrames = null,
    Object? aspect = null,
    Object? xSqCount = null,
    Object? ySqCount = null,
  }) {
    return _then(_$RTCDetectedFramesImpl(
      rawFrames: null == rawFrames
          ? _value._rawFrames
          : rawFrames // ignore: cast_nullable_to_non_nullable
              as Map<String, List<dynamic>>,
      aspect: null == aspect
          ? _value.aspect
          : aspect // ignore: cast_nullable_to_non_nullable
              as double,
      xSqCount: null == xSqCount
          ? _value.xSqCount
          : xSqCount // ignore: cast_nullable_to_non_nullable
              as int,
      ySqCount: null == ySqCount
          ? _value.ySqCount
          : ySqCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RTCDetectedFramesImpl extends _RTCDetectedFrames {
  _$RTCDetectedFramesImpl(
      {@JsonKey(name: "f") required final Map<String, List<dynamic>> rawFrames,
      @JsonKey(name: "a") required this.aspect,
      @JsonKey(name: "x") required this.xSqCount,
      @JsonKey(name: "y") required this.ySqCount})
      : _rawFrames = rawFrames,
        super._();

  factory _$RTCDetectedFramesImpl.fromJson(Map<String, dynamic> json) =>
      _$$RTCDetectedFramesImplFromJson(json);

  final Map<String, List<dynamic>> _rawFrames;
  @override
  @JsonKey(name: "f")
  Map<String, List<dynamic>> get rawFrames {
    if (_rawFrames is EqualUnmodifiableMapView) return _rawFrames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_rawFrames);
  }

  @override
  @JsonKey(name: "a")
  final double aspect;
  @override
  @JsonKey(name: "x")
  final int xSqCount;
  @override
  @JsonKey(name: "y")
  final int ySqCount;

  @override
  String toString() {
    return 'DetectionData(rawFrames: $rawFrames, aspect: $aspect, xSqCount: $xSqCount, ySqCount: $ySqCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RTCDetectedFramesImpl &&
            const DeepCollectionEquality()
                .equals(other._rawFrames, _rawFrames) &&
            (identical(other.aspect, aspect) || other.aspect == aspect) &&
            (identical(other.xSqCount, xSqCount) ||
                other.xSqCount == xSqCount) &&
            (identical(other.ySqCount, ySqCount) ||
                other.ySqCount == ySqCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_rawFrames),
      aspect,
      xSqCount,
      ySqCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RTCDetectedFramesImplCopyWith<_$RTCDetectedFramesImpl> get copyWith =>
      __$$RTCDetectedFramesImplCopyWithImpl<_$RTCDetectedFramesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RTCDetectedFramesImplToJson(
      this,
    );
  }
}

abstract class _RTCDetectedFrames extends DetectionData {
  factory _RTCDetectedFrames(
      {@JsonKey(name: "f") required final Map<String, List<dynamic>> rawFrames,
      @JsonKey(name: "a") required final double aspect,
      @JsonKey(name: "x") required final int xSqCount,
      @JsonKey(name: "y")
      required final int ySqCount}) = _$RTCDetectedFramesImpl;
  _RTCDetectedFrames._() : super._();

  factory _RTCDetectedFrames.fromJson(Map<String, dynamic> json) =
      _$RTCDetectedFramesImpl.fromJson;

  @override
  @JsonKey(name: "f")
  Map<String, List<dynamic>> get rawFrames;
  @override
  @JsonKey(name: "a")
  double get aspect;
  @override
  @JsonKey(name: "x")
  int get xSqCount;
  @override
  @JsonKey(name: "y")
  int get ySqCount;
  @override
  @JsonKey(ignore: true)
  _$$RTCDetectedFramesImplCopyWith<_$RTCDetectedFramesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
