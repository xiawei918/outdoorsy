import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((event) {
    // If there's a session, return the user
    if (event.session != null) {
      return event.session!.user;
    }
    // If there's no session but we have a skipped user, return that
    if (authService.currentUser?.id == 'mock-user') {
      return authService.currentUser;
    }
    // Otherwise return null
    return null;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => ref.read(authServiceProvider).currentUser,
    error: (_, __) => null,
  );
}); 