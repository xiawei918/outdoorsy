import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../auth/domain/models/user_settings.dart';
import 'package:logging/logging.dart';

class SettingsService {
  final _supabase = SupabaseConfig.client;
  final _logger = Logger('SettingsService');

  Future<UserSettings?> getUserSettings(String userId) async {
    try {
      _logger.info('Fetching settings from Supabase for user: $userId');
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .single();

      _logger.info('Supabase response: $response');

      if (response == null) {
        _logger.info('No settings found in Supabase');
        return null;
      }

      // Ensure we have all required fields
      if (response['user_id'] == null || response['daily_goal'] == null) {
        _logger.info('Missing required fields in response');
        return null;
      }

      // Handle updated_at which could be either String or DateTime
      final updatedAt = response['updated_at'] is DateTime 
          ? response['updated_at'] as DateTime 
          : DateTime.parse(response['updated_at'] as String);

      final lastStreakCheck = response['last_streak_check'] != null
          ? (response['last_streak_check'] is DateTime 
              ? response['last_streak_check'] as DateTime 
              : DateTime.parse(response['last_streak_check'] as String))
          : DateTime.now();

      return UserSettings(
        userId: response['user_id'],
        dailyGoal: response['daily_goal'],
        streak: response['streak'] ?? 0,
        lastStreakCheck: lastStreakCheck,
        updatedAt: updatedAt,
        locationName: response['location_name'] ?? '',
      );
    } catch (e) {
      _logger.severe('Error fetching settings', e);
      return null;
    }
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      _logger.info('Attempting to update settings for user: ${settings.userId}');
      
      final response = await _supabase
          .from('user_settings')
          .upsert({
            'user_id': settings.userId,
            'daily_goal': settings.dailyGoal,
            'streak': settings.streak,
            'last_streak_check': settings.lastStreakCheck.toIso8601String(),
            'updated_at': settings.updatedAt.toIso8601String(),
            'location_name': settings.locationName,
          })
          .select()
          .single();
          
      _logger.info('Update response: $response');
      
      if (response == null) {
        throw Exception('Failed to update settings: No response from Supabase');
      }
    } catch (e) {
      _logger.severe('Error updating settings', e);
      rethrow;
    }
  }

  Future<void> createDefaultSettings(String userId) async {
    final defaultSettings = UserSettings(
      userId: userId,
      dailyGoal: 30 * 60, // 30 minutes in seconds
      streak: 0,
      lastStreakCheck: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await updateUserSettings(defaultSettings);
  }
} 