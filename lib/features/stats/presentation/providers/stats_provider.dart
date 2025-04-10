import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/domain/models/time_entry.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class StatsState {
  final int totalSeconds;
  final int activeDays;
  final int currentStreak;
  final int daysMetGoal;
  final bool isLoading;
  final String? error;

  StatsState({
    required this.totalSeconds,
    required this.activeDays,
    required this.currentStreak,
    required this.daysMetGoal,
    this.isLoading = false,
    this.error,
  });

  StatsState copyWith({
    int? totalSeconds,
    int? activeDays,
    int? currentStreak,
    int? daysMetGoal,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      activeDays: activeDays ?? this.activeDays,
      currentStreak: currentStreak ?? this.currentStreak,
      daysMetGoal: daysMetGoal ?? this.daysMetGoal,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final Ref _ref;

  StatsNotifier(this._ref) : super(StatsState(
    totalSeconds: 0,
    activeDays: 0,
    currentStreak: 0,
    daysMetGoal: 0,
    isLoading: true,
  )) {
    // Listen to changes in history provider
    _ref.listen(historyProvider, (previous, next) {
      next.when(
        data: (entries) {
          _updateStats(entries);
        },
        loading: () {
          state = state.copyWith(isLoading: true, error: null);
        },
        error: (error, stackTrace) {
          state = state.copyWith(
            isLoading: false,
            error: error.toString(),
          );
        },
      );
    });

    // Listen to changes in daily goal
    _ref.listen(settingsProvider, (previous, next) {
      if (previous?.dailyGoal != next.dailyGoal) {
        _ref.read(historyProvider).whenData((entries) {
          _updateStats(entries);
        });
      }
    });
  }

  void _updateStats(List<TimeEntry> entries) {
    try {
      // Get the daily goal from settings
      final settings = _ref.read(settingsProvider);
      final dailyGoal = settings.dailyGoal;

      // Calculate stats for all historical data
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Create a map of dates to total duration for all entries
      final dateMap = <DateTime, int>{};
      for (final entry in entries) {
        final date = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        dateMap[date] = (dateMap[date] ?? 0) + entry.duration;
      }

      // Calculate total time
      final totalSeconds = dateMap.values.fold<int>(0, (sum, duration) => sum + duration);

      // Calculate active days (days with any activity)
      final activeDays = dateMap.length;

      // Calculate current streak (excluding today since it hasn't finished)
      int currentStreak = 0;
      DateTime currentDate = today.subtract(const Duration(days: 1)); // Start from yesterday
      while (true) {
        final totalDuration = dateMap[currentDate] ?? 0;
        if (totalDuration < dailyGoal) break;
        
        currentStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      // Calculate days that met the goal in all history
      var daysMetGoal = 0;
      for (final entry in dateMap.entries) {
        if (entry.value >= dailyGoal) {
          daysMetGoal++;
        }
      }

      state = state.copyWith(
        totalSeconds: totalSeconds,
        activeDays: activeDays,
        currentStreak: currentStreak,
        daysMetGoal: daysMetGoal,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref);
}); 