import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import 'user_service.dart';

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _userService = UserService();
  User? _skippedUser;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _skippedUser = null;
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _skippedUser = null;
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
      },
    );

    // Create initial user data if signup was successful
    if (response.user != null) {
      await _userService.createInitialUserData(response.user!, name);
    }

    return response;
  }

  Future<void> signInWithGoogle() async {
    _skippedUser = null;
    final response = await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.outdoor://login-callback/',
    );

    // Create initial user data if this is the first time signing in
    if (response && _auth.currentUser != null) {
      final user = _auth.currentUser!;
      final name = user.userMetadata?['full_name'] as String? ?? 'User';
      try {
        await _userService.createInitialUserData(user, name);
      } catch (e) {
        // Ignore if user data already exists
      }
    }
  }

  Future<void> signInWithApple() async {
    _skippedUser = null;
    final response = await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.outdoor://login-callback/',
    );

    // Create initial user data if this is the first time signing in
    if (response && _auth.currentUser != null) {
      final user = _auth.currentUser!;
      final name = user.userMetadata?['name'] as String? ?? 'User';
      try {
        await _userService.createInitialUserData(user, name);
      } catch (e) {
        // Ignore if user data already exists
      }
    }
  }

  void skipAuth() {
    _skippedUser = User(
      id: 'mock-user',
      appMetadata: {},
      userMetadata: {'name': 'Guest User'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<void> signOut() async {
    try {
      // Clear the skipped user first
      _skippedUser = null;
      
      // Sign out from Supabase
      await _auth.signOut();
      
      // Create a new skipped user for guest mode
      skipAuth();
    } catch (e) {
      // If there's an error, still try to set up guest mode
      skipAuth();
      rethrow;
    }
  }

  User? get currentUser {
    // If we have a Supabase user, return that
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    }
    // Otherwise return the skipped user
    return _skippedUser;
  }

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
} 