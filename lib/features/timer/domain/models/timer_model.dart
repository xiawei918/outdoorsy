import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_model.freezed.dart';
part 'timer_model.g.dart';

@freezed
class TimerModel with _$TimerModel {
  const factory TimerModel({
    required int dailyGoal,
    required int currentProgress,
    required int streak,
    required bool isRunning,
    required DateTime lastUpdated,
  }) = _TimerModel;

  factory TimerModel.fromJson(Map<String, dynamic> json) =>
      _$TimerModelFromJson(json);

  factory TimerModel.initial() => TimerModel(
        dailyGoal: 1800, // 30 minutes in seconds
        currentProgress: 0,
        streak: 0,
        isRunning: false,
        lastUpdated: DateTime.now(),
      );
}

extension TimerModelX on TimerModel {
  double get progressPercent => (currentProgress / dailyGoal).clamp(0.0, 1.0);

  String get formattedProgress {
    final hours = currentProgress ~/ 3600;
    final minutes = (currentProgress % 3600) ~/ 60;
    final seconds = currentProgress % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDailyGoal {
    final minutes = dailyGoal ~/ 60;
    return '$minutes minutes';
  }
} 