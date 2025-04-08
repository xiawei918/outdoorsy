import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../timer/presentation/widgets/progress_ring.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/domain/models/time_entry.dart';
import '../../../stats/presentation/pages/stats_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/location_provider.dart';
import '../../../../core/providers/mock_data_provider.dart';
import '../../../../core/providers/stats_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rounded_button.dart';
import '../../../../core/widgets/settings_card.dart';
import '../../../../core/widgets/settings_section.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../../core/widgets/settings_dropdown.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../providers/sunset_provider.dart';
import '../../../../core/providers/tips_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Timer state
  int sessionProgress = 0; // seconds
  bool isRunning = false;
  DateTime? _startTime;
  Timer? _timer;
  
  // Navigation state
  int _selectedIndex = 0;
  
  // Mock data
  final String sunsetTime = '7:30 PM';

  late TextEditingController _goalController;
  late TextEditingController _locationController;
  bool _hasRequestedLocation = false;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _locationController = TextEditingController();
    
    // Request location permission after a short delay to ensure the page is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasRequestedLocation) {
        _requestLocationPermission();
      }
    });

    // Check for daily tip refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  void _requestLocationPermission() {
    _hasRequestedLocation = true;
    ref.read(locationProvider.notifier).requestLocationPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _goalController.dispose();
    _locationController.dispose();
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
  
  // MARK: - UI Building Methods

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locationState = ref.watch(locationProvider);
    final stats = ref.watch(statsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);

    // Mock data
    final String sunsetTime = '7:30 PM';
    
    // Update settings with location if available
    if (locationState.locationString.isNotEmpty && settings.locationName.isEmpty) {
      Future.microtask(() {
        ref.read(settingsProvider.notifier).updateLocation(locationState.locationString);
      });
    }

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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
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
    );
  }

  Widget _buildHomeContent() {
    final settings = ref.watch(settingsProvider);
    final dailyGoal = settings.dailyGoal;
    final currentUser = ref.watch(currentUserProvider);
    
    // Calculate total progress for today
    final totalProgress = _calculateTotalProgress();
    final progressPercent = (totalProgress / dailyGoal).clamp(0.0, 1.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUserGreeting(currentUser),
            const SizedBox(height: 16),
            _buildWeeklyActivity(),
            const SizedBox(height: 16),
            _buildSunsetDisplay(),
            const SizedBox(height: 16),
            _buildTimerSection(progressPercent),
            _buildDailyTip(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserGreeting(User? currentUser) {
    return Text(
      'Hi ${currentUser?.userMetadata?['name'] ?? 'Guest'}',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ).animate().slideY(begin: -0.2, end: 0);
  }
  
  Widget _buildTimerSection(double progressPercent) {
    final settings = ref.watch(settingsProvider);
    final dailyGoal = settings.dailyGoal;
    
    return Expanded(
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
                '${(sessionProgress / 60).floor()}:${(sessionProgress % 60).toString().padLeft(2, '0')}',
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
    final locationState = ref.watch(locationProvider);
    final sunsetTimeAsync = ref.watch(sunsetProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wb_twilight, size: 24),
        const SizedBox(width: 8),
        if (locationState.isLoading || sunsetTimeAsync.isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          sunsetTimeAsync.when(
            data: (sunsetTime) => Text(
              'Sunset at $sunsetTime',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'Sunset at 7:30 PM',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildDailyTip() {
    final tipState = ref.watch(tipsProvider);
    
    return Container(
      height: 80, // Fixed height for the tip container
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                tipState.tip,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tipsProvider.notifier).refreshTip(),
          ),
        ],
      ),
    );
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