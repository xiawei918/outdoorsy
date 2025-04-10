import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/supabase_config.dart';
import 'user_service.dart';
import '../../domain/models/profile.dart';

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _userService = UserService();
  final _logger = Logger('AuthService');

  // Get the redirect URL for mobile
  String get _redirectUrl => 'io.supabase.outdoor://login-callback/';

  // Get the redirect URL for password reset on mobile
  String get _resetPasswordRedirectUrl => 'io.supabase.outdoor://reset-password/';

  // Check if Supabase is initialized
  bool get _isInitialized => Supabase.instance.client.auth != null;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      _logger.info('Supabase not initialized, initializing now...');
      await SupabaseConfig.initialize();
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _logger.info('Starting sign in process for email: $email');
    
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _logger.info('Sign in successful. User ID: ${response.user?.id}');
      
      if (response.user != null) {
        final user = response.user!;
        final name = user.userMetadata?['name'] as String? ?? 'User';
        _logger.info('User metadata - name: $name');
        
        try {
          // Check if profile exists
          final existingProfile = await _userService.getProfile(user.id);
          _logger.info('Existing profile found: ${existingProfile.name}');
          
          // If profile exists but name is different, update it
          if (existingProfile.name != name) {
            _logger.info('Updating profile name to match metadata');
            await _userService.updateProfile(Profile(
              id: user.id,
              name: name,
              avatarUrl: existingProfile.avatarUrl,
              createdAt: existingProfile.createdAt,
              updatedAt: DateTime.now(),
            ));
          }
        } catch (e) {
          _logger.info('No existing profile found, creating initial data');
          try {
            await _userService.createInitialUserData(user, name);
            _logger.info('Initial user data created successfully');
          } catch (dataError) {
            _logger.warning('Error creating initial user data: $dataError');
            // Continue with sign in even if data creation fails
          }
        }
      }
      
      return response;
    } catch (e) {
      _logger.severe('Error during sign in process: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _logger.info('Starting sign up process for email: $email, name: $name');
    
    try {
      // First verify the auth configuration
      _logger.info('Verifying auth configuration...');
      _logger.info('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      _logger.info('Auth client initialized: ${_auth != null}');
      
      // Sign up with user metadata included
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'name': name},  // Include name in initial metadata
      );
      
      _logger.info('Sign up response received:');
      _logger.info('User ID: ${response.user?.id}');
      _logger.info('Session: ${response.session != null ? 'Created' : 'Not created'}');
      _logger.info('Email confirmation required: ${response.user?.emailConfirmedAt == null}');
      _logger.info('User metadata: ${response.user?.userMetadata}');
      
      if (response.user == null) {
        throw Exception('Sign up failed: No user returned in response');
      }
      
      // Create profile and settings
      if (response.user != null) {
        try {
          _logger.info('Creating profile and settings for user: ${response.user!.id}');
          await _userService.createInitialUserData(response.user!, name);
          _logger.info('Successfully created profile and settings');
        } catch (dataError) {
          _logger.warning('Error creating profile and settings: $dataError');
          // Continue anyway as the user was created successfully
        }
      }
      
      if (response.session == null) {
        _logger.info('Note: No session created - this is expected as email confirmation is required');
      }
      
      return response;
    } catch (e) {
      _logger.severe('Error during sign up process: $e');
      if (e is AuthException) {
        _logger.info('Auth error details:');
        _logger.info('Status code: ${e.statusCode}');
        _logger.info('Message: ${e.message}');
        
        // Handle specific error cases
        if (e.statusCode == 500) {
          if (e.message.contains('already registered')) {
            throw Exception('This email is already registered. Please try signing in instead.');
          } else if (e.message.contains('invalid email')) {
            throw Exception('Please enter a valid email address.');
          } else if (e.message.contains('weak password')) {
            throw Exception('Please choose a stronger password.');
          } else {
            _logger.severe('Database error occurred. This might be due to:');
            _logger.severe('1. Missing or incorrect auth.users table');
            _logger.severe('2. Incorrect permissions on the auth schema');
            _logger.severe('3. Database configuration issues');
            _logger.severe('4. Trigger function error');
            throw Exception('Unable to create account. Please try again later or contact support if the issue persists.');
          }
        }
      }
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    _logger.info('Starting password reset process for email: $email');
    
    try {
      // First verify the auth configuration
      _logger.info('Verifying auth configuration...');
      _logger.info('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      _logger.info('Auth client initialized: ${_auth != null}');
      
      // Send password reset email
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: _resetPasswordRedirectUrl,
      );
      
      _logger.info('Password reset email sent successfully');
    } catch (e) {
      _logger.severe('Error during password reset process: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    _logger.info('Starting Google sign in process');
    
    try {
      await _ensureInitialized();
      
      // First verify the auth configuration
      _logger.info('Verifying auth configuration...');
      _logger.info('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      _logger.info('Auth client initialized: ${_auth != null}');
      
      // Sign in with Google
      final response = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
      );
      
      _logger.info('Google sign in response received');
      
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
    } catch (e) {
      _logger.severe('Error during Google sign in process: $e');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    _logger.info('Starting Apple sign in process');
    
    try {
      // First verify the auth configuration
      _logger.info('Verifying auth configuration...');
      _logger.info('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      _logger.info('Auth client initialized: ${_auth != null}');
      
      // Sign in with Apple
      final response = await _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _redirectUrl,
      );
      
      _logger.info('Apple sign in response received');
      
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
    } catch (e) {
      _logger.severe('Error during Apple sign in process: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _logger.info('Starting sign out process');
      await _auth.signOut();
      _logger.info('Sign out successful');
    } catch (e) {
      _logger.severe('Error during sign out: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
} 