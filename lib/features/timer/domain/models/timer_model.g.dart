// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimerModelImpl _$$TimerModelImplFromJson(Map<String, dynamic> json) =>
    _$TimerModelImpl(
      dailyGoal: (json['dailyGoal'] as num).toInt(),
      currentProgress: (json['currentProgress'] as num).toInt(),
      streak: (json['streak'] as num).toInt(),
      isRunning: json['isRunning'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$TimerModelImplToJson(_$TimerModelImpl instance) =>
    <String, dynamic>{
      'dailyGoal': instance.dailyGoal,
      'currentProgress': instance.currentProgress,
      'streak': instance.streak,
      'isRunning': instance.isRunning,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
