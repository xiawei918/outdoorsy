import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/mock_data_provider.dart';
import '../../../../core/providers/stats_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/rounded_button.dart';
import '../../../../core/widgets/settings_card.dart';
import '../../../../core/widgets/settings_section.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../../core/widgets/settings_dropdown.dart';

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
    final mockData = ref.read(mockDataProvider);
    _goalController = TextEditingController(
      text: (mockData.dailyGoal / 60).round().toString(),
    );
    _locationController = TextEditingController(text: 'New York, NY');
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
      ref.read(mockDataProvider.notifier).updateDailyGoal(minutes * 60);
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

  @override
  Widget build(BuildContext context) {
    final mockData = ref.watch(mockDataProvider);
    final stats = ref.watch(statsProvider);

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
                      'User Name',
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
                      'Location',
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
                        IconButton(
                          onPressed: () {
                            _locationController.clear();
                          },
                          icon: const Icon(Icons.cancel),
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
                            'Setting your location helps us provide accurate sunset times and local weather information.',
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

              // Display & Units Settings
              SettingsSection(
                title: 'Display & Units',
                subtitle: 'Customize how information is displayed',
                icon: Icons.wb_sunny,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsDropdown(
                      label: 'Temperature Units',
                      value: 'fahrenheit',
                      items: const [
                        DropdownMenuItem(
                          value: 'fahrenheit',
                          child: Text('Fahrenheit (°F)'),
                        ),
                        DropdownMenuItem(
                          value: 'celsius',
                          child: Text('Celsius (°C)'),
                        ),
                      ],
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 16),
                    SettingsDropdown(
                      label: 'Language',
                      value: 'english',
                      items: const [
                        DropdownMenuItem(
                          value: 'english',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'spanish',
                          child: Text('Spanish'),
                        ),
                        DropdownMenuItem(
                          value: 'french',
                          child: Text('French'),
                        ),
                      ],
                      onChanged: (value) {},
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
                            'Choose your preferred units and language settings.',
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

              // Notifications Settings
              SettingsSection(
                title: 'Notifications',
                icon: Icons.notifications,
                child: Column(
                  children: [
                    SettingsToggle(
                      title: 'Push Notifications',
                      subtitle: 'Receive reminders for outdoor time',
                      value: true,
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 16),
                    SettingsToggle(
                      title: 'Email Notifications',
                      subtitle: 'Weekly summary of your outdoor time',
                      value: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              RoundedButton(
                onPressed: () {},
                text: 'Log out',
                icon: Icons.logout,
                backgroundColor: Colors.white,
                textColor: AppColors.gray700,
                borderColor: AppColors.gray200,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 