// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'record_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecordError _$RecordErrorFromJson(Map<String, dynamic> json) {
  return _RecordError.fromJson(json);
}

/// @nodoc
mixin _$RecordError {
  String get code => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecordErrorCopyWith<RecordError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordErrorCopyWith<$Res> {
  factory $RecordErrorCopyWith(
          RecordError value, $Res Function(RecordError) then) =
      _$RecordErrorCopyWithImpl<$Res, RecordError>;
  @useResult
  $Res call({String code, String? message, Map<String, dynamic>? details});
}

/// @nodoc
class _$RecordErrorCopyWithImpl<$Res, $Val extends RecordError>
    implements $RecordErrorCopyWith<$Res> {
  _$RecordErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = freezed,
    Object? details = freezed,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecordErrorImplCopyWith<$Res>
    implements $RecordErrorCopyWith<$Res> {
  factory _$$RecordErrorImplCopyWith(
          _$RecordErrorImpl value, $Res Function(_$RecordErrorImpl) then) =
      __$$RecordErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String code, String? message, Map<String, dynamic>? details});
}

/// @nodoc
class __$$RecordErrorImplCopyWithImpl<$Res>
    extends _$RecordErrorCopyWithImpl<$Res, _$RecordErrorImpl>
    implements _$$RecordErrorImplCopyWith<$Res> {
  __$$RecordErrorImplCopyWithImpl(
      _$RecordErrorImpl _value, $Res Function(_$RecordErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = freezed,
    Object? details = freezed,
  }) {
    return _then(_$RecordErrorImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordErrorImpl implements _RecordError {
  const _$RecordErrorImpl(
      {required this.code, this.message, final Map<String, dynamic>? details})
      : _details = details;

  factory _$RecordErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordErrorImplFromJson(json);

  @override
  final String code;
  @override
  final String? message;
  final Map<String, dynamic>? _details;
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'RecordError(code: $code, message: $message, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordErrorImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, code, message,
      const DeepCollectionEquality().hash(_details));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordErrorImplCopyWith<_$RecordErrorImpl> get copyWith =>
      __$$RecordErrorImplCopyWithImpl<_$RecordErrorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordErrorImplToJson(
      this,
    );
  }
}

abstract class _RecordError implements RecordError {
  const factory _RecordError(
      {required final String code,
      final String? message,
      final Map<String, dynamic>? details}) = _$RecordErrorImpl;

  factory _RecordError.fromJson(Map<String, dynamic> json) =
      _$RecordErrorImpl.fromJson;

  @override
  String get code;
  @override
  String? get message;
  @override
  Map<String, dynamic>? get details;
  @override
  @JsonKey(ignore: true)
  _$$RecordErrorImplCopyWith<_$RecordErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
