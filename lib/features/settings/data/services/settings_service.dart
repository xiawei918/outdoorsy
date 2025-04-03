import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/models/user_settings.dart';

class SettingsService {
  final _supabase = SupabaseConfig.client;

  Future<UserSettings?> getUserSettings(String userId) async {
    try {
      print('Fetching settings from Supabase for user: $userId');
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .single();

      print('Supabase response: $response');

      if (response == null) {
        print('No settings found in Supabase');
        return null;
      }

      // Ensure we have all required fields
      if (response['user_id'] == null || response['daily_goal'] == null) {
        print('Missing required fields in response');
        return null;
      }

      // Handle updated_at which could be either String or DateTime
      final updatedAt = response['updated_at'] is DateTime 
          ? response['updated_at'] as DateTime 
          : DateTime.parse(response['updated_at'] as String);

      return UserSettings.fromJson({
        'userId': response['user_id'],
        'dailyGoal': response['daily_goal'],
        'locationName': response['location_name'] ?? '',
        'updatedAt': updatedAt.toIso8601String(),
      });
    } catch (e) {
      print('Error fetching settings: $e');
      return null;
    }
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      print('Attempting to update settings for user: ${settings.userId}');
      print('Settings to update: ${settings.toJson()}');
      
      final response = await _supabase
          .from('user_settings')
          .upsert({
            'user_id': settings.userId,
            'daily_goal': settings.dailyGoal,
            'location_name': settings.locationName,
            'updated_at': settings.updatedAt.toIso8601String(),
          })
          .select()
          .single();
          
      print('Update response: $response');
      
      if (response == null) {
        throw Exception('Failed to update settings: No response from Supabase');
      }
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  Future<void> createDefaultSettings(String userId) async {
    final defaultSettings = UserSettings(
      userId: userId,
      dailyGoal: 30 * 60, // 30 minutes in seconds
      locationName: '',
      updatedAt: DateTime.now(),
    );

    await updateUserSettings(defaultSettings);
  }
} 