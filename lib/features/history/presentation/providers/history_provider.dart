import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/time_entry.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/services/time_entry_service.dart';

final timeEntryServiceProvider = Provider<TimeEntryService>((ref) {
  return TimeEntryService();
});

final historyProvider = StateNotifierProvider<HistoryNotifier, AsyncValue<List<TimeEntry>>>((ref) {
  return HistoryNotifier(ref);
});

class HistoryNotifier extends StateNotifier<AsyncValue<List<TimeEntry>>> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Start with loading state
    state = const AsyncValue.loading();

    // Get the current user
    final user = _ref.read(currentUserProvider);
    
    if (user != null) {
      await _loadUserEntries(user.id);
    } else {
      state = const AsyncValue.data([]);
    }

    // Listen to auth state changes
    _ref.listen(currentUserProvider, (previous, next) {
      if (next == null) {
        state = const AsyncValue.data([]);
      } else if (previous?.id != next.id) {
        _loadUserEntries(next.id);
      }
    });
  }

  Future<void> _loadUserEntries(String userId) async {
    try {
      state = const AsyncValue.loading();
      final entries = await _ref.read(timeEntryServiceProvider).getTimeEntries(userId);
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTimeEntry({
    required DateTime date,
    required int duration,
    required bool isManual,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final entry = await _ref.read(timeEntryServiceProvider).addTimeEntry(
        userId: user.id,
        startTime: date,
        date: date,
        duration: duration,
        endTime: date,
        isManual: isManual,
      );
      final currentEntries = state.value ?? [];
      state = AsyncValue.data([...currentEntries, entry]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _ref.read(timeEntryServiceProvider).deleteTimeEntry(id);
      final currentEntries = state.value ?? [];
      state = AsyncValue.data(currentEntries.where((entry) => entry.id != id).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> editEntry(String id, int newDuration) async {
    try {
      final updatedEntry = await _ref.read(timeEntryServiceProvider).updateTimeEntry(
        id: id,
        duration: newDuration,
      );
      final currentEntries = state.value ?? [];
      state = AsyncValue.data(currentEntries.map((entry) {
        if (entry.id == id) {
          return updatedEntry;
        }
        return entry;
      }).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<TimeEntry> getTodayEntries() {
    return state.when(
      data: (entries) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return entries.where((entry) {
          final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
          return entryDate.isAtSameMomentAs(today);
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<TimeEntry> getFilteredEntries(int days) {
    return state.when(
      data: (entries) {
        final cutoffDate = DateTime.now().subtract(Duration(days: days));
        return entries.where((entry) => entry.date.isAfter(cutoffDate)).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  int getTodayProgress() {
    return getTodayEntries().fold(0, (sum, entry) => sum + entry.duration);
  }
} 