import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/domain/models/time_entry.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../../core/providers/mock_data_provider.dart';

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref);
});

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

class StatsNotifier extends StateNotifier<StatsState> {
  final Ref _ref;

  StatsNotifier(this._ref) : super(StatsState(
    totalSeconds: _ref.read(mockDataProvider).totalOutdoorTime,
    activeDays: _ref.read(mockDataProvider).activeDays,
    currentStreak: _ref.read(mockDataProvider).currentStreak,
    daysMetGoal: _ref.read(mockDataProvider).daysMetGoal,
    dailyGoal: _ref.read(mockDataProvider).dailyGoal,
  )) {
    // Listen to changes in mock data provider
    _ref.listen(mockDataProvider, (previous, next) {
      state = state.copyWith(
        totalSeconds: next.totalOutdoorTime,
        activeDays: next.activeDays,
        currentStreak: next.currentStreak,
        daysMetGoal: next.daysMetGoal,
        dailyGoal: next.dailyGoal,
      );
    });
  }

  void setDailyGoal(int minutes) {
    state = state.copyWith(dailyGoal: minutes * 60);
  }
} 