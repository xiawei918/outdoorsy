import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/timer_model.dart';

final timerProvider = StateNotifierProvider<TimerNotifier, TimerModel>((ref) {
  return TimerNotifier();
});

class TimerNotifier extends StateNotifier<TimerModel> {
  Timer? _timer;
  Timer? _midnightCheckTimer;

  TimerNotifier() : super(TimerModel.initial()) {
    _setupMidnightCheck();
  }

  void _setupMidnightCheck() {
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 0 && now.minute == 0) {
        _resetDailyProgress();
      }
    });
  }

  void startTimer() {
    if (!state.isRunning) {
      state = state.copyWith(
        isRunning: true,
        lastUpdated: DateTime.now(),
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(
          currentProgress: state.currentProgress + 1,
          lastUpdated: DateTime.now(),
        );
      });
    }
  }

  void stopTimer() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(
        isRunning: false,
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _resetDailyProgress() {
    stopTimer();
    state = state.copyWith(
      currentProgress: 0,
      lastUpdated: DateTime.now(),
    );
  }

  void updateDailyGoal(int seconds) {
    state = state.copyWith(
      dailyGoal: seconds,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }
} 