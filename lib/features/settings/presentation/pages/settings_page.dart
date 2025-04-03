import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/mock_data_provider.dart';
import '../providers/settings_provider.dart';
import '../../../../core/providers/stats_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rounded_button.dart';
import '../../../../core/widgets/settings_card.dart';
import '../../../../core/widgets/settings_section.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../../core/widgets/settings_dropdown.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _goalController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _locationController.dispose();
    super.dispose();
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

  void _handleLocationUpdate() {
    final location = _locationController.text.trim();
    if (location.isNotEmpty) {
      ref.read(settingsProvider.notifier).updateLocation(location);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(statsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);

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
                    const SizedBox(height: 16),
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
                title: 'Location',
                subtitle: 'Set your location for accurate sunset times',
                icon: Icons.location_on,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your location',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoundedButton(
                          onPressed: _handleLocationUpdate,
                          text: 'Update',
                        ),
                      ],
                    ),
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
} 