import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/user_settings.dart';

class UserService {
  final _client = SupabaseConfig.client;

  Future<Profile> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(response);
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .upsert({
          'id': profile.id,
          'name': profile.name,
          'avatar_url': profile.avatarUrl,
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
        });
  }

  Future<void> createInitialUserData(User user, String name) async {
    // Create profile
    await _client.from('profiles').insert({
      'id': user.id,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Create user settings with default values
    await _client.from('user_settings').insert({
      'user_id': user.id,
      'daily_goal': 1800, // 30 minutes in seconds
      'streak': 0,
      'last_streak_check': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
} 