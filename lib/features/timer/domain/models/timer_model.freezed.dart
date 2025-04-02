// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TimerModel _$TimerModelFromJson(Map<String, dynamic> json) {
  return _TimerModel.fromJson(json);
}

/// @nodoc
mixin _$TimerModel {
  int get dailyGoal => throw _privateConstructorUsedError;
  int get currentProgress => throw _privateConstructorUsedError;
  int get streak => throw _privateConstructorUsedError;
  bool get isRunning => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this TimerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimerModelCopyWith<TimerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimerModelCopyWith<$Res> {
  factory $TimerModelCopyWith(
          TimerModel value, $Res Function(TimerModel) then) =
      _$TimerModelCopyWithImpl<$Res, TimerModel>;
  @useResult
  $Res call(
      {int dailyGoal,
      int currentProgress,
      int streak,
      bool isRunning,
      DateTime lastUpdated});
}

/// @nodoc
class _$TimerModelCopyWithImpl<$Res, $Val extends TimerModel>
    implements $TimerModelCopyWith<$Res> {
  _$TimerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyGoal = null,
    Object? currentProgress = null,
    Object? streak = null,
    Object? isRunning = null,
    Object? lastUpdated = null,
  }) {
    return _then(_value.copyWith(
      dailyGoal: null == dailyGoal
          ? _value.dailyGoal
          : dailyGoal // ignore: cast_nullable_to_non_nullable
              as int,
      currentProgress: null == currentProgress
          ? _value.currentProgress
          : currentProgress // ignore: cast_nullable_to_non_nullable
              as int,
      streak: null == streak
          ? _value.streak
          : streak // ignore: cast_nullable_to_non_nullable
              as int,
      isRunning: null == isRunning
          ? _value.isRunning
          : isRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimerModelImplCopyWith<$Res>
    implements $TimerModelCopyWith<$Res> {
  factory _$$TimerModelImplCopyWith(
          _$TimerModelImpl value, $Res Function(_$TimerModelImpl) then) =
      __$$TimerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int dailyGoal,
      int currentProgress,
      int streak,
      bool isRunning,
      DateTime lastUpdated});
}

/// @nodoc
class __$$TimerModelImplCopyWithImpl<$Res>
    extends _$TimerModelCopyWithImpl<$Res, _$TimerModelImpl>
    implements _$$TimerModelImplCopyWith<$Res> {
  __$$TimerModelImplCopyWithImpl(
      _$TimerModelImpl _value, $Res Function(_$TimerModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyGoal = null,
    Object? currentProgress = null,
    Object? streak = null,
    Object? isRunning = null,
    Object? lastUpdated = null,
  }) {
    return _then(_$TimerModelImpl(
      dailyGoal: null == dailyGoal
          ? _value.dailyGoal
          : dailyGoal // ignore: cast_nullable_to_non_nullable
              as int,
      currentProgress: null == currentProgress
          ? _value.currentProgress
          : currentProgress // ignore: cast_nullable_to_non_nullable
              as int,
      streak: null == streak
          ? _value.streak
          : streak // ignore: cast_nullable_to_non_nullable
              as int,
      isRunning: null == isRunning
          ? _value.isRunning
          : isRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimerModelImpl implements _TimerModel {
  const _$TimerModelImpl(
      {required this.dailyGoal,
      required this.currentProgress,
      required this.streak,
      required this.isRunning,
      required this.lastUpdated});

  factory _$TimerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimerModelImplFromJson(json);

  @override
  final int dailyGoal;
  @override
  final int currentProgress;
  @override
  final int streak;
  @override
  final bool isRunning;
  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'TimerModel(dailyGoal: $dailyGoal, currentProgress: $currentProgress, streak: $streak, isRunning: $isRunning, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimerModelImpl &&
            (identical(other.dailyGoal, dailyGoal) ||
                other.dailyGoal == dailyGoal) &&
            (identical(other.currentProgress, currentProgress) ||
                other.currentProgress == currentProgress) &&
            (identical(other.streak, streak) || other.streak == streak) &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, dailyGoal, currentProgress, streak, isRunning, lastUpdated);

  /// Create a copy of TimerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimerModelImplCopyWith<_$TimerModelImpl> get copyWith =>
      __$$TimerModelImplCopyWithImpl<_$TimerModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimerModelImplToJson(
      this,
    );
  }
}

abstract class _TimerModel implements TimerModel {
  const factory _TimerModel(
      {required final int dailyGoal,
      required final int currentProgress,
      required final int streak,
      required final bool isRunning,
      required final DateTime lastUpdated}) = _$TimerModelImpl;

  factory _TimerModel.fromJson(Map<String, dynamic> json) =
      _$TimerModelImpl.fromJson;

  @override
  int get dailyGoal;
  @override
  int get currentProgress;
  @override
  int get streak;
  @override
  bool get isRunning;
  @override
  DateTime get lastUpdated;

  /// Create a copy of TimerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimerModelImplCopyWith<_$TimerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
