import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../timer/presentation/widgets/progress_ring.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'goal_achieved_modal.dart';

class TimerWidget extends ConsumerStatefulWidget {
  const TimerWidget({super.key});

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  // Timer state
  int sessionProgress = 0; // seconds
  bool isRunning = false;
  DateTime? _startTime;
  Timer? _timer;
  bool _hasShownGoalModal = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // MARK: - Timer Methods
  
  void _startTimer() {
    setState(() {
      isRunning = true;
      sessionProgress = 0;
      _startTime = DateTime.now();
    });
    
    // Start a timer that updates every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          sessionProgress++;
          _checkGoalAchievement();
        });
      }
    });
  }

  void _stopTimer() {
    // Cancel the timer
    _timer?.cancel();
    _timer = null;
    
    // Calculate the final duration
    final finalDuration = sessionProgress;
    
    // Save the session to history
    if (_startTime != null) {
      ref.read(historyProvider.notifier).addTimeEntry(
        date: _startTime!,
        duration: finalDuration,
        isManual: false,
      );
    }
    
    // Reset the timer state
    setState(() {
      isRunning = false;
      sessionProgress = 0;
      _startTime = null;
    });
  }

  void _toggleTimer() {
    if (isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }
  
  // MARK: - Helper Methods
  
  int _calculateTotalProgress() {
    // Watch the history provider to react to changes
    final history = ref.watch(historyProvider);
    
    // Calculate total progress for today
    int totalProgress = 0;  // Start with 0
    
    // Add progress from history entries if available
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
          totalProgress += entry.duration;
        }
      }
    }
    
    // Add current session duration if timer is running
    if (isRunning) {
      totalProgress += sessionProgress;
    }
    
    return totalProgress;
  }

  void _checkGoalAchievement() {
    if (_hasShownGoalModal) return;
    
    final settings = ref.read(settingsProvider);
    final dailyGoal = settings.dailyGoal;
    final totalProgress = _calculateTotalProgress();
    
    if (totalProgress >= dailyGoal) {
      _showGoalAchievedModal();
    }
  }

  void _showGoalAchievedModal() {
    if (!_hasShownGoalModal && mounted) {
      _hasShownGoalModal = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const GoalAchievedModal(),
      );
    }
  }
  
  // Format seconds to a readable time string
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildGoalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            'Daily Goal Achieved!',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final dailyGoal = settings.dailyGoal;
    
    // Calculate total progress for today
    final totalProgress = _calculateTotalProgress();
    final progressPercent = (totalProgress / dailyGoal).clamp(0.0, 1.0);
    final hasMetGoal = totalProgress >= dailyGoal;
    
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Timer in the center
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleTimer,
                child: ProgressRing(
                  progress: progressPercent,
                  size: 280,
                  strokeWidth: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(totalProgress),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daily goal: ${dailyGoal ~/ 60} min',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildTimerButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Goal badge positioned at the bottom
          if (hasMetGoal)
            Positioned(
              bottom: 16,
              child: _buildGoalBadge(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTimerButton() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRunning ? Icons.stop : Icons.play_arrow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isRunning ? 'Tap to stop' : 'Tap to start',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
} 