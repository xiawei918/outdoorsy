import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mock_data_provider.dart';

class StatsState {
  final int totalSeconds;
  final int activeDays;
  final int currentStreak;
  final int daysMetGoal;
  final int dailyGoal;

  StatsState({
    required this.totalSeconds,
    required this.activeDays,
    required this.currentStreak,
    required this.daysMetGoal,
    required this.dailyGoal,
  });

  StatsState copyWith({
    int? totalSeconds,
    int? activeDays,
    int? currentStreak,
    int? daysMetGoal,
    int? dailyGoal,
  }) {
    return StatsState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      activeDays: activeDays ?? this.activeDays,
      currentStreak: currentStreak ?? this.currentStreak,
      daysMetGoal: daysMetGoal ?? this.daysMetGoal,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

final statsProvider = Provider<StatsState>((ref) {
  final mockData = ref.watch(mockDataProvider);
  return StatsState(
    totalSeconds: mockData.totalOutdoorTime,
    activeDays: mockData.activeDays,
    currentStreak: mockData.currentStreak,
    daysMetGoal: mockData.daysMetGoal,
    dailyGoal: mockData.dailyGoal,
  );
}); 