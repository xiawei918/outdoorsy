import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/domain/models/time_entry.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../../core/providers/mock_data_provider.dart';

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
  }

  void _updateStats(List<TimeEntry> entries) {
    try {
      // Get the daily goal from mock data (this is the same for both mock and real data)
      final mockData = _ref.read(mockDataProvider);
      final dailyGoal = mockData.dailyGoal;

      // Calculate stats for the last 7 days
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // Create a map of dates to total duration for the last 7 days
      final dateMap = <DateTime, int>{};
      for (final entry in entries) {
        final date = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        if (date.isAfter(sevenDaysAgo) || date.isAtSameMomentAs(sevenDaysAgo)) {
          dateMap[date] = (dateMap[date] ?? 0) + entry.duration;
        }
      }

      // Calculate total time
      final totalSeconds = dateMap.values.fold<int>(0, (sum, duration) => sum + duration);

      // Calculate active days (days with any activity)
      final activeDays = dateMap.length;

      // Calculate current streak
      int currentStreak = 0;
      DateTime currentDate = today;
      while (true) {
        final hasEntry = entries.any((entry) => 
          entry.date.year == currentDate.year &&
          entry.date.month == currentDate.month &&
          entry.date.day == currentDate.day
        );
        
        if (!hasEntry) break;
        
        currentStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      // Calculate days that met the goal
      final daysMetGoal = dateMap.values.where((duration) => duration >= dailyGoal).length;

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