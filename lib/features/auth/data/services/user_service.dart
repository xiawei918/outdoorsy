import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/user_settings.dart';

class UserService {
  final _client = SupabaseConfig.client;
  final _logger = Logger('UserService');

  Future<Profile> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
        _logger.info('Profile response: $response');
    return Profile.fromJson({
      'id': response['id'],
      'name': response['name'],
      'avatarUrl': response['avatar_url'],
      'createdAt': response['created_at'],
      'updatedAt': response['updated_at'],
    });
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .upsert({
          'id': profile.id,
          'name': profile.name,
          'avatar_url': profile.avatarUrl ?? null,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  Future<UserSettings> getUserSettings(String userId) async {
    final response = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .single();
    return UserSettings.fromJson(response);
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    await _client
        .from('user_settings')
        .upsert({
          'user_id': settings.userId,
          'daily_goal': settings.dailyGoal,
          'streak': settings.streak,
          'last_streak_check': settings.lastStreakCheck.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'location_name': settings.locationName,
        });
  }

  Future<void> createInitialUserData(User user, String name) async {
    // First, check if the tables exist
    try {
      _logger.info('Checking if tables exist...');
      await _client.from('profiles').select('id').limit(1);
      await _client.from('user_settings').select('user_id').limit(1);
      _logger.info('Tables exist, proceeding with data creation');
    } catch (e) {
      _logger.severe('Error checking tables: $e');
      throw Exception('Database tables may not exist: $e');
    }

    // Create or update profile
    try {
      _logger.info('Creating/updating profile for user: ${user.id}');
      await _client.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      _logger.info('Profile created/updated successfully');
    } catch (e) {
      _logger.warning('Error creating/updating profile: $e');
      // Continue to try creating settings even if profile fails
    }

    // Create or update settings
    try {
      _logger.info('Creating/updating settings for user: ${user.id}');
      await _client.from('user_settings').upsert({
        'user_id': user.id,
        'daily_goal': 1800, // 30 minutes in seconds
        'streak': 0,
        'last_streak_check': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'location_name': '', // Initialize with empty location
      });
      _logger.info('Settings created/updated successfully');
    } catch (e) {
      _logger.severe('Error creating/updating settings: $e');
      throw Exception('Failed to create/update user settings: $e');
    }
  }
} 