import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../features/history/domain/models/time_entry.dart';

class MockData {
  final List<TimeEntry> timeEntries;
  final int currentStreak;
  final int longestStreak;
  final int daysMetGoal;
  final int totalOutdoorTime;
  final int activeDays;
  final int dailyGoal;

  MockData({
    required this.timeEntries,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysMetGoal,
    required this.totalOutdoorTime,
    required this.activeDays,
    required this.dailyGoal,
  });

  MockData copyWith({
    List<TimeEntry>? timeEntries,
    int? currentStreak,
    int? longestStreak,
    int? daysMetGoal,
    int? totalOutdoorTime,
    int? activeDays,
    int? dailyGoal,
  }) {
    return MockData(
      timeEntries: timeEntries ?? this.timeEntries,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      daysMetGoal: daysMetGoal ?? this.daysMetGoal,
      totalOutdoorTime: totalOutdoorTime ?? this.totalOutdoorTime,
      activeDays: activeDays ?? this.activeDays,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

class MockDataNotifier extends StateNotifier<MockData> {
  MockDataNotifier() : super(_createInitialData());

  static MockData _createInitialData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final fourDaysAgo = today.subtract(const Duration(days: 4));
    final fiveDaysAgo = today.subtract(const Duration(days: 5));

    // Create time entries with varying durations
    final timeEntries = [
      // Today's entries - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        startTime: today,
        endTime: today,
        duration: 45 * 60, // 45 minutes
        date: today,
        isManual: false,
      ),
      TimeEntry(
        id: const Uuid().v4(),
        startTime: today,
        endTime: today,
        duration: 30 * 60, // 30 minutes
        date: today,
        isManual: true,
      ),

      // Yesterday's entries - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        startTime: yesterday,
        endTime: yesterday,
        duration: 60 * 60, // 60 minutes
        date: yesterday,
        isManual: false,
      ),

      // Two days ago - no activity (skipped)

      // Three days ago - below goal
      TimeEntry(
        id: const Uuid().v4(),
        startTime: threeDaysAgo,
        endTime: threeDaysAgo,
        duration: 15 * 60, // 15 minutes (below 30 min goal)
        date: threeDaysAgo,
        isManual: true,
      ),

      // Four days ago - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        startTime: fourDaysAgo,
        endTime: fourDaysAgo,
        duration: 45 * 60, // 45 minutes
        date: fourDaysAgo,
        isManual: false,
      ),

      // Five days ago - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        startTime: fiveDaysAgo,
        endTime: fiveDaysAgo,
        duration: 60 * 60, // 60 minutes
        date: fiveDaysAgo,
        isManual: false,
      ),
    ];

    // Calculate statistics
    final dailyGoal = 30 * 60; // 30 minutes in seconds
    final uniqueDates = <DateTime>{};
    var totalOutdoorTime = 0;
    var daysMetGoal = 0;
    var currentStreak = 0;
    var longestStreak = 0;
    var tempStreak = 0;

    // Process entries in chronological order
    final sortedEntries = List<TimeEntry>.from(timeEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final entry in sortedEntries) {
      // Track unique dates
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      uniqueDates.add(entryDate);

      // Calculate total time
      totalOutdoorTime += entry.duration;

      // Calculate streaks
      if (entry.duration >= dailyGoal) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        if (entryDate.isAtSameMomentAs(today) || 
            entryDate.isAtSameMomentAs(yesterday)) {
          currentStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // Calculate days that met the goal
    final dateMap = <DateTime, int>{};
    for (final entry in timeEntries) {
      final date = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      dateMap[date] = (dateMap[date] ?? 0) + entry.duration;
    }
    daysMetGoal = dateMap.values.where((seconds) => seconds >= dailyGoal).length;

    return MockData(
      timeEntries: timeEntries,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      dailyGoal: dailyGoal,
      daysMetGoal: daysMetGoal,
      totalOutdoorTime: totalOutdoorTime,
      activeDays: uniqueDates.length,
    );
  }

  void updateTimeEntries(List<TimeEntry> entries) {
    state = state.copyWith(timeEntries: entries);
    _calculateStats();
  }

  void updateDailyGoal(int seconds) {
    state = state.copyWith(dailyGoal: seconds);
    _calculateStats();
  }

  void _calculateStats() {
    final entries = state.timeEntries;
    if (entries.isEmpty) {
      state = state.copyWith(
        currentStreak: 0,
        longestStreak: 0,
        daysMetGoal: 0,
        totalOutdoorTime: 0,
        activeDays: 0,
      );
      return;
    }

    // Sort entries by date in descending order
    entries.sort((a, b) => b.date.compareTo(a.date));

    // Calculate total outdoor time and active days
    final totalSeconds = entries.fold(0, (sum, entry) => sum + entry.duration);
    final activeDays = entries.map((e) => e.date).toSet().length;

    // Calculate streaks and days met goal
    int currentStreak = 0;
    int longestStreak = 0;
    int daysMetGoal = 0;
    int tempStreak = 0;

    // Group entries by date
    final entriesByDate = <DateTime, int>{};
    for (final entry in entries) {
      entriesByDate[entry.date] = (entriesByDate[entry.date] ?? 0) + entry.duration;
    }

    // Sort dates in descending order
    final sortedDates = entriesByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    // Calculate streaks
    for (final date in sortedDates) {
      final totalDuration = entriesByDate[date]!;
      if (totalDuration >= state.dailyGoal) {
        daysMetGoal++;
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        if (currentStreak == 0) {
          currentStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    state = state.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      daysMetGoal: daysMetGoal,
      totalOutdoorTime: totalSeconds,
      activeDays: activeDays,
    );
  }
}

final mockDataProvider = StateNotifierProvider<MockDataNotifier, MockData>((ref) {
  return MockDataNotifier();
}); 