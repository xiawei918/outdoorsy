import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../features/history/domain/models/time_entry.dart';

final mockDataProvider = StateNotifierProvider<MockDataNotifier, MockData>((ref) {
  return MockDataNotifier();
});

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
    final List<TimeEntry> timeEntries = [
      // Today's entries - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        userId: 'mock-user',
        startTime: today,
        endTime: today,
        duration: 45 * 60, // 45 minutes
        date: today,
        isManual: false,
        createdAt: now,
      ),
      TimeEntry(
        id: const Uuid().v4(),
        userId: 'mock-user',
        startTime: today,
        endTime: today,
        duration: 30 * 60, // 30 minutes
        date: today,
        isManual: true,
        createdAt: now,
      ),

      // Yesterday's entries - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        userId: 'mock-user',
        startTime: yesterday,
        endTime: yesterday,
        duration: 60 * 60, // 60 minutes
        date: yesterday,
        isManual: false,
        createdAt: now,
      ),

      // Three days ago - below goal
      TimeEntry(
        id: const Uuid().v4(),
        userId: 'mock-user',
        startTime: threeDaysAgo,
        endTime: threeDaysAgo,
        duration: 15 * 60, // 15 minutes (below 30 min goal)
        date: threeDaysAgo,
        isManual: true,
        createdAt: now,
      ),

      // Four days ago - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        userId: 'mock-user',
        startTime: fourDaysAgo,
        endTime: fourDaysAgo,
        duration: 45 * 60, // 45 minutes
        date: fourDaysAgo,
        isManual: false,
        createdAt: now,
      ),

      // Five days ago - meets goal
      TimeEntry(
        id: const Uuid().v4(),
        userId: 'mock-user',
        startTime: fiveDaysAgo,
        endTime: fiveDaysAgo,
        duration: 60 * 60, // 60 minutes
        date: fiveDaysAgo,
        isManual: false,
        createdAt: now,
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
      timeEntries: List<TimeEntry>.from(timeEntries),
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      dailyGoal: dailyGoal,
      daysMetGoal: daysMetGoal,
      totalOutdoorTime: totalOutdoorTime,
      activeDays: uniqueDates.length,
    );
  }

  void updateTimeEntries(List<TimeEntry> entries) {
    state = state.copyWith(timeEntries: List<TimeEntry>.from(entries));
    _calculateStats();
  }

  void updateDailyGoal(int newGoal) {
    state = state.copyWith(dailyGoal: newGoal);
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final uniqueDates = <DateTime>{};
    var totalOutdoorTime = 0;
    var daysMetGoal = 0;
    var currentStreak = 0;
    var longestStreak = 0;
    var tempStreak = 0;

    // Process entries in chronological order
    final sortedEntries = List<TimeEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final entry in sortedEntries) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      uniqueDates.add(entryDate);
      totalOutdoorTime += entry.duration;

      if (entry.duration >= state.dailyGoal) {
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
    for (final entry in entries) {
      final date = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      dateMap[date] = (dateMap[date] ?? 0) + entry.duration;
    }
    daysMetGoal = dateMap.values.where((seconds) => seconds >= state.dailyGoal).length;

    state = state.copyWith(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      daysMetGoal: daysMetGoal,
      totalOutdoorTime: totalOutdoorTime,
      activeDays: uniqueDates.length,
    );
  }
} 