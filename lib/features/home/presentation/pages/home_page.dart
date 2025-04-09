import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../stats/presentation/pages/stats_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/location_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/daily_tip.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/weekly_activity.dart';
import '../widgets/sunset_display.dart';
import '../widgets/timer_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Navigation state
  int _selectedIndex = 0;
  bool _hasRequestedLocation = false;

  @override
  void initState() {
    super.initState();
    
    // Request location permission after a short delay to ensure the page is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasRequestedLocation) {
        _requestLocationPermission();
      }
    });
  }

  void _requestLocationPermission() {
    _hasRequestedLocation = true;
    ref.read(locationProvider.notifier).requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locationState = ref.watch(locationProvider);
    
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
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    final currentUser = ref.watch(currentUserProvider);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUserGreeting(currentUser),
            const SizedBox(height: 16),
            const WeeklyActivity(),
            const SizedBox(height: 16),
            const SunsetDisplay(),
            const SizedBox(height: 16),
            const TimerWidget(),
            const SizedBox(height: 16),
            const DailyTip(),
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
} 