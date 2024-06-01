// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'record_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecordEvent _$RecordEventFromJson(Map<String, dynamic> json) {
  return _RecordEvent.fromJson(json);
}

/// @nodoc
mixin _$RecordEvent {
  RecordEventType get type => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecordEventCopyWith<RecordEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordEventCopyWith<$Res> {
  factory $RecordEventCopyWith(
          RecordEvent value, $Res Function(RecordEvent) then) =
      _$RecordEventCopyWithImpl<$Res, RecordEvent>;
  @useResult
  $Res call({RecordEventType type, Map<String, dynamic>? data});
}

/// @nodoc
class _$RecordEventCopyWithImpl<$Res, $Val extends RecordEvent>
    implements $RecordEventCopyWith<$Res> {
  _$RecordEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as RecordEventType,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecordEventImplCopyWith<$Res>
    implements $RecordEventCopyWith<$Res> {
  factory _$$RecordEventImplCopyWith(
          _$RecordEventImpl value, $Res Function(_$RecordEventImpl) then) =
      __$$RecordEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RecordEventType type, Map<String, dynamic>? data});
}

/// @nodoc
class __$$RecordEventImplCopyWithImpl<$Res>
    extends _$RecordEventCopyWithImpl<$Res, _$RecordEventImpl>
    implements _$$RecordEventImplCopyWith<$Res> {
  __$$RecordEventImplCopyWithImpl(
      _$RecordEventImpl _value, $Res Function(_$RecordEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = freezed,
  }) {
    return _then(_$RecordEventImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as RecordEventType,
      data: freezed == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordEventImpl implements _RecordEvent {
  const _$RecordEventImpl(
      {required this.type, final Map<String, dynamic>? data})
      : _data = data;

  factory _$RecordEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordEventImplFromJson(json);

  @override
  final RecordEventType type;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'RecordEvent(type: $type, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordEventImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, const DeepCollectionEquality().hash(_data));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordEventImplCopyWith<_$RecordEventImpl> get copyWith =>
      __$$RecordEventImplCopyWithImpl<_$RecordEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordEventImplToJson(
      this,
    );
  }
}

abstract class _RecordEvent implements RecordEvent {
  const factory _RecordEvent(
      {required final RecordEventType type,
      final Map<String, dynamic>? data}) = _$RecordEventImpl;

  factory _RecordEvent.fromJson(Map<String, dynamic> json) =
      _$RecordEventImpl.fromJson;

  @override
  RecordEventType get type;
  @override
  Map<String, dynamic>? get data;
  @override
  @JsonKey(ignore: true)
  _$$RecordEventImplCopyWith<_$RecordEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
