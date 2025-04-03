import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/user_service.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/user_settings.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final userService = ref.watch(userServiceProvider);
  return await userService.getProfile(user.id);
});

final userSettingsProvider = FutureProvider<UserSettings?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final userService = ref.watch(userServiceProvider);
  return await userService.getUserSettings(user.id);
}); 