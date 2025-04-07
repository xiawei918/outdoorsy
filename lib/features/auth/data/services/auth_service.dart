import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import 'user_service.dart';
import '../../domain/models/profile.dart';

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _userService = UserService();
  User? _skippedUser;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _skippedUser = null;
    print('Starting sign in process for email: $email');
    
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('Sign in successful. User ID: ${response.user?.id}');
      
      if (response.user != null) {
        final user = response.user!;
        final name = user.userMetadata?['name'] as String? ?? 'User';
        print('User metadata - name: $name');
        
        // try {
          // Check if profile exists
        final existingProfile = await _userService.getProfile(user.id);
        print('Existing profile found: ${existingProfile.name}');
        
        // If profile exists but name is different, update it
        if (existingProfile.name != name) {
          print('Updating profile name to match metadata');
          await _userService.updateProfile(Profile(
            id: user.id,
            name: name,
            avatarUrl: existingProfile.avatarUrl,
            createdAt: existingProfile.createdAt,
            updatedAt: DateTime.now(),
          ));
        }
        // } catch (e) {
        //   print(e)
        //   print('No existing profile found, creating initial data');
        //   try {
        //     await _userService.createInitialUserData(user, name);
        //     print('Initial user data created successfully');
        //   } catch (dataError) {
        //     print('Error creating initial user data: $dataError');
        //     // Continue with sign in even if data creation fails
        //   }
        // }
      }
      
      return response;
    } catch (e) {
      print('Error during sign in process: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _skippedUser = null;
    print('Starting sign up process for email: $email, name: $name');
    
    try {
      // First verify the auth configuration
      print('Verifying auth configuration...');
      print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      print('Auth client initialized: ${_auth != null}');
      
      // Sign up with user metadata included
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'name': name},  // Include name in initial metadata
      );
      
      print('Sign up response received:');
      print('User ID: ${response.user?.id}');
      print('Session: ${response.session != null ? 'Created' : 'Not created'}');
      print('Email confirmation required: ${response.user?.emailConfirmedAt == null}');
      print('User metadata: ${response.user?.userMetadata}');
      
      if (response.user == null) {
        throw Exception('Sign up failed: No user returned in response');
      }
      
      // Create profile and settings
      if (response.user != null) {
        try {
          print('Creating profile and settings for user: ${response.user!.id}');
          await _userService.createInitialUserData(response.user!, name);
          print('Successfully created profile and settings');
        } catch (dataError) {
          print('Error creating profile and settings: $dataError');
          // Continue anyway as the user was created successfully
        }
      }
      
      if (response.session == null) {
        print('Note: No session created - this is expected as email confirmation is required');
      }
      
      return response;
    } catch (e) {
      print('Error during sign up process: $e');
      if (e is AuthException) {
        print('Auth error details:');
        print('Status code: ${e.statusCode}');
        print('Message: ${e.message}');
        
        // Handle specific error cases
        if (e.statusCode == 500) {
          if (e.message.contains('already registered')) {
            throw Exception('This email is already registered. Please try signing in instead.');
          } else if (e.message.contains('invalid email')) {
            throw Exception('Please enter a valid email address.');
          } else if (e.message.contains('weak password')) {
            throw Exception('Please choose a stronger password.');
          } else {
            print('Database error occurred. This might be due to:');
            print('1. Missing or incorrect auth.users table');
            print('2. Incorrect permissions on the auth schema');
            print('3. Database configuration issues');
            print('4. Trigger function error');
            throw Exception('Unable to create account. Please try again later or contact support if the issue persists.');
          }
        }
      }
      rethrow;
    }
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