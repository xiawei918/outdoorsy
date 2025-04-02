import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/time_entry.dart';
import '../../../../core/providers/mock_data_provider.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, List<TimeEntry>>((ref) {
  return HistoryNotifier(ref);
});

class HistoryNotifier extends StateNotifier<List<TimeEntry>> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super([]) {
    _updateEntries();
  }

  void _updateEntries() {
    state = _ref.read(mockDataProvider).timeEntries;
  }

  void addTimeEntry({
    required DateTime date,
    required int duration,
    required bool isManual,
  }) {
    final entry = TimeEntry(
      id: const Uuid().v4(),
      startTime: date,
      endTime: date,
      duration: duration,
      date: date,
      isManual: isManual,
    );
    state = [...state, entry];
    _ref.read(mockDataProvider.notifier).updateTimeEntries(state);
  }

  void deleteEntry(String id) {
    state = state.where((entry) => entry.id != id).toList();
    _ref.read(mockDataProvider.notifier).updateTimeEntries(state);
  }

  void editEntry(String id, int newDuration) {
    state = state.map((entry) {
      if (entry.id == id) {
        return entry.copyWith(duration: newDuration);
      }
      return entry;
    }).toList();
    _ref.read(mockDataProvider.notifier).updateTimeEntries(state);
  }

  List<TimeEntry> getTodayEntries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return entryDate.isAtSameMomentAs(today);
    }).toList();
  }

  List<TimeEntry> getFilteredEntries(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return state.where((entry) => entry.date.isAfter(cutoffDate)).toList();
  }

  int getTodayProgress() {
    return getTodayEntries().fold(0, (sum, entry) => sum + entry.duration);
  }
} 