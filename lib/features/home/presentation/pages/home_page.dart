import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../timer/presentation/providers/timer_provider.dart';
import '../../../timer/presentation/widgets/progress_ring.dart';
import '../../../timer/domain/models/timer_model.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../stats/presentation/pages/stats_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/providers/mock_data_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Mock data for initial development
  final String sunsetTime = '7:30 PM';
  int sessionProgress = 0; // minutes
  bool isRunning = false;
  int _selectedIndex = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    // Start a timer to update session progress when running
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateSessionProgress();
      }
    });
  }

  void _updateSessionProgress() {
    if (isRunning && _startTime != null) {
      setState(() {
        final now = DateTime.now();
        final difference = now.difference(_startTime!);
        sessionProgress = difference.inSeconds;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _updateSessionProgress();
        }
      });
    }
  }

  void _toggleTimer() {
    setState(() {
      if (isRunning) {
        isRunning = false;
        
        // Add the completed session to history
        if (_startTime != null) {
          ref.read(historyProvider.notifier).addTimeEntry(
            date: _startTime!,
            duration: sessionProgress,
            isManual: false,
          );
        }
        
        sessionProgress = 0;
        _startTime = null;
      } else {
        isRunning = true;
        sessionProgress = 0;
        _startTime = DateTime.now();
        _updateSessionProgress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          const HistoryPage(),
          const StatsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final settings = ref.watch(settingsProvider);
    final dailyGoal = settings.dailyGoal;
    final currentUser = ref.watch(currentUserProvider);
    
    // Get total progress from history entries
    final totalProgress = ref.watch(historyProvider.notifier).getTodayProgress() + sessionProgress;
    final progressPercent = (totalProgress / dailyGoal).clamp(0.0, 1.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User greeting
            Text(
              'Hi ${currentUser?.userMetadata?['name'] ?? 'Guest'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ).animate().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // Weekly activity display
            _buildWeeklyActivity(),

            const SizedBox(height: 16),

            // Sunset time display
            _buildSunsetDisplay(),

            const SizedBox(height: 16),

            // Main timer section
            Expanded(
              child: GestureDetector(
                onTap: _toggleTimer,
                child: ProgressRing(
                  progress: progressPercent,
                  size: 280,
                  strokeWidth: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(totalProgress / 60).floor()}:${(totalProgress % 60).toString().padLeft(2, '0')}',
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
                      Container(
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
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Daily tip section
            _buildDailyTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivity() {
    final settings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return history.when(
      data: (entries) {
        // Create a map of dates to total duration for the last 7 days
        final dateMap = <DateTime, int>{};
        for (final entry in entries) {
          final date = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          dateMap[date] = (dateMap[date] ?? 0) + entry.duration;
        }
        
        // Generate activity data for the last 7 days
        final days = List.generate(7, (index) {
          final date = today.subtract(Duration(days: 6 - index));
          final duration = dateMap[date] ?? 0;
          final isActive = duration >= settings.dailyGoal;
          return {
            'date': date,
            'hasActivity': isActive,
          };
        });

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days.map((day) {
            return Column(
              children: [
                Text(
                  _getDayName(day['date'] as DateTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (day['hasActivity'] as bool)
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildSunsetDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wb_sunny, size: 24),
        const SizedBox(width: 8),
        Text(
          'Sunset at $sunsetTime',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildDailyTip() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Stay hydrated and bring water with you',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
} 