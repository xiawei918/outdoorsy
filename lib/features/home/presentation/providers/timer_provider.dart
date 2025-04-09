import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../history/presentation/providers/history_provider.dart';

// Timer state class to encapsulate all timer-related state
class TimerState {
  final bool isRunning;
  final DateTime? startTime;
  final int currentSessionDuration;
  final int totalDuration;

  TimerState({
    required this.isRunning,
    this.startTime,
    required this.currentSessionDuration,
    required this.totalDuration,
  });

  // Create a copy of this state with some fields replaced
  TimerState copyWith({
    bool? isRunning,
    DateTime? startTime,
    int? currentSessionDuration,
    int? totalDuration,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
      currentSessionDuration: currentSessionDuration ?? this.currentSessionDuration,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

// Timer notifier to manage timer state
class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  final Ref _ref;

  TimerNotifier(this._ref) : super(TimerState(
    isRunning: false,
    startTime: null,
    currentSessionDuration: 0,
    totalDuration: 0,
  ));

  // Start the timer
  void startTimer() {
    if (state.isRunning) return;

    final now = DateTime.now();
    
    // Cancel any existing timer
    _timer?.cancel();
    
    // Create a new timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.startTime != null) {
        final currentTime = DateTime.now();
        final duration = currentTime.difference(state.startTime!).inSeconds;
        
        // Update the state with the new duration
        state = state.copyWith(
          currentSessionDuration: duration,
          totalDuration: _calculateTotalDuration(duration),
        );
      }
    });
    
    // Update the state to start the timer
    state = state.copyWith(
      isRunning: true,
      startTime: now,
      currentSessionDuration: 0,
      totalDuration: _calculateTotalDuration(0),
    );
  }

  // Stop the timer and save the session
  void stopTimer() {
    if (!state.isRunning || state.startTime == null) return;
    
    // Calculate the final duration
    final now = DateTime.now();
    final finalDuration = now.difference(state.startTime!).inSeconds;
    
    // Cancel the timer
    _timer?.cancel();
    _timer = null;
    
    // Update the state to stop the timer but keep the current session duration
    state = state.copyWith(
      isRunning: false,
      startTime: null,
      currentSessionDuration: finalDuration,
      totalDuration: _calculateTotalDuration(finalDuration),
    );
    
    // Save the session to history in the background
    _ref.read(historyProvider.notifier).addTimeEntry(
      date: state.startTime!,
      duration: finalDuration,
      isManual: false,
    );
  }

  // Calculate the total duration including history entries
  int _calculateTotalDuration(int currentDuration) {
    final history = _ref.read(historyProvider);
    int total = 0;  // Start with 0, not currentDuration
    
    if (history.hasValue) {
      final entries = history.value!;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // Sum up all entries from today
      for (final entry in entries) {
        final entryDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        
        if (entryDate.isAtSameMomentAs(todayStart)) {
          total += entry.duration;
        }
      }
    }
    
    // Only add current session duration if timer is running
    if (state.isRunning) {
      total += currentDuration;
    }
    
    return total;
  }

  // Update the total duration when history changes
  void updateTotalDuration() {
    state = state.copyWith(
      totalDuration: _calculateTotalDuration(state.currentSessionDuration),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Provider for the timer state
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final timer = TimerNotifier(ref);
  
  // Listen to history changes and update the total duration
  ref.listen(historyProvider, (previous, next) {
    if (previous != next) {
      timer.updateTotalDuration();
    }
  });
  
  return timer;
}); 