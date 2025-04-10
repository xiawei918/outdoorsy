import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/settings_provider.dart';
import '../providers/location_provider.dart';
import '../providers/location_suggestions_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rounded_button.dart';
import '../../../../core/widgets/settings_card.dart';
import '../../../../core/widgets/settings_section.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _goalController;
  late TextEditingController _locationController;
  final FocusNode _locationFocusNode = FocusNode();
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _locationController = TextEditingController();
    
    // Add listener to location controller
    _locationController.addListener(_onLocationTextChanged);
    
    // Add listener to focus node
    _locationFocusNode.addListener(_onLocationFocusChanged);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onLocationTextChanged() {
    // No need to handle text changes since the field is disabled
  }

  void _onLocationFocusChanged() {
    // Hide suggestions when focus is lost
    if (!_locationFocusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _handleGoalCommit() {
    final minutes = int.tryParse(_goalController.text);
    if (minutes != null && minutes > 0) {
      _updateDailyGoal(minutes);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily goal updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of minutes'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateDailyGoal(int minutes) {
    ref.read(settingsProvider.notifier).updateDailyGoal(minutes);
  }

  void _requestLocationPermission() {
    ref.read(locationProvider.notifier).requestLocationPermission().then((_) {
      final locationState = ref.read(locationProvider);
      if (locationState.locationString.isNotEmpty) {
        _locationController.text = locationState.locationString;
        ref.read(settingsProvider.notifier).updateLocation(locationState.locationString);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locationState = ref.watch(locationProvider);
    final locationSuggestions = ref.watch(locationSuggestionsProvider);
    final stats = ref.watch(statsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);

    // Set the location controller text when the location state changes
    if (locationState.locationString.isNotEmpty && 
        _locationController.text.isEmpty) {
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(() {
        _locationController.text = locationState.locationString;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User Profile Section
              SettingsCard(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.gray400,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser?.userMetadata?['name'] ?? 'Guest User',
                      style: AppTypography.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: AppColors.gray700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${stats.currentStreak}-Day Streak',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.gray700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daily Goal Settings
              SettingsSection(
                title: 'Daily Goal',
                subtitle: 'Set your daily outdoor time goal',
                icon: Icons.timer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minutes per day',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _goalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: '${(settings.dailyGoal / 60).round()}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoundedButton(
                          onPressed: _handleGoalCommit,
                          text: 'Commit',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Research suggests at least 15-30 minutes of outdoor time daily can positively impact your mood and health.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location Settings
              SettingsSection(
                title: 'City & State',
                subtitle: 'Set your location for accurate sunset times',
                icon: Icons.location_on,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your city and state',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _locationController,
                                focusNode: _locationFocusNode,
                                enabled: false, // Disable the text field
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  hintText: 'Unknown',
                                  filled: true, // Add a background color to indicate it's disabled
                                  fillColor: Colors.grey[200],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _requestLocationPermission,
                              tooltip: 'Use device location',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (locationState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (!locationState.isLocationEnabled)
                      _buildLocationDisabledMessage()
                    else if (locationState.permission == LocationPermission.denied || 
                             locationState.permission == LocationPermission.deniedForever)
                      _buildLocationPermissionRequest()
                    else if (locationState.locationString.isEmpty)
                      _buildLocationRefreshButton()
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign In/Out Button
              SizedBox(
                width: double.infinity,
                child: RoundedButton(
                  onPressed: () {
                    if (currentUser == null) {
                      context.push('/auth');
                    } else {
                      authService.signOut();
                    }
                  },
                  text: currentUser == null ? 'Sign In' : 'Sign Out',
                  backgroundColor: currentUser == null ? AppColors.primary : AppColors.error,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDisabledMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off,
            size: 20,
            color: AppColors.gray700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location services are disabled. Please enable them in your device settings to automatically detect your city and state.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionRequest() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_disabled,
            size: 20,
            color: AppColors.gray700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location permission is needed to identify your city and state for accurate sunset times.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRefreshButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.refresh,
            size: 20,
            color: AppColors.gray700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not detect your city and state. Please try again.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RoundedButton(
            onPressed: () {
              ref.read(locationProvider.notifier).refreshLocation();
            },
            text: 'Refresh',
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
} 