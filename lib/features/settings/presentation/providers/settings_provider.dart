import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../../auth/domain/models/user_settings.dart';
import '../../data/services/settings_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/location_provider.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

class SettingsState {
  final int dailyGoal;
  final String locationName;
  final bool isLoading;
  final String? error;
  final int streak;
  final DateTime? lastStreakCheck;

  SettingsState({
    required this.dailyGoal,
    required this.locationName,
    this.isLoading = false,
    this.error,
    required this.streak,
    required this.lastStreakCheck,
  });

  SettingsState copyWith({
    int? dailyGoal,
    String? locationName,
    bool? isLoading,
    String? error,
    int? streak,
    DateTime? lastStreakCheck,
  }) {
    return SettingsState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      streak: streak ?? this.streak,
      lastStreakCheck: lastStreakCheck ?? this.lastStreakCheck,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  int? _lastKnownDailyGoal;
  final _logger = Logger('SettingsNotifier');

  SettingsNotifier(this._ref) : super(SettingsState(
    dailyGoal: 30 * 60, // Start with default 30 minutes in seconds
    locationName: '',
    isLoading: true,
    streak: 0,
    lastStreakCheck: null,
  )) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = _ref.read(currentUserProvider);
      
      if (user != null) {
        await _loadUserSettings(user.id);
      } else {
        state = state.copyWith(
          dailyGoal: 30 * 60, // Default 30 minutes
          locationName: '',
          isLoading: false,
        );
        _lastKnownDailyGoal = 30 * 60;
      }

      // Listen to auth state changes
      _ref.listen(currentUserProvider, (previous, next) {
        if (next == null) {
          state = state.copyWith(
            dailyGoal: 30 * 60, // Default 30 minutes
            locationName: '',
            isLoading: false,
          );
          _lastKnownDailyGoal = 30 * 60;
        } else {
          _loadUserSettings(next.id);
        }
      });
      
      // Listen to location changes
      _ref.listen(locationProvider, (previous, next) {
        if (next.locationString.isNotEmpty && state.locationName.isEmpty) {
          updateLocation(next.locationString);
        }
      });
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> _loadUserSettings(String userId) async {
    try {
      state = state.copyWith(isLoading: true);
      final settings = await _ref.read(settingsServiceProvider).getUserSettings(userId);
      
      if (settings == null) {
        // Create default settings if none exist
        final defaultSettings = UserSettings(
          userId: userId,
          dailyGoal: 30 * 60, // 30 minutes in seconds
          streak: 0,
          lastStreakCheck: DateTime.now(),
          updatedAt: DateTime.now(),
          locationName: '',
        );
        await _ref.read(settingsServiceProvider).updateUserSettings(defaultSettings);
        
        state = state.copyWith(
          dailyGoal: defaultSettings.dailyGoal,
          locationName: defaultSettings.locationName,
          streak: defaultSettings.streak,
          lastStreakCheck: defaultSettings.lastStreakCheck,
          isLoading: false,
        );
        _lastKnownDailyGoal = defaultSettings.dailyGoal;
      } else {
        state = state.copyWith(
          dailyGoal: settings.dailyGoal,
          locationName: settings.locationName,
          streak: settings.streak,
          lastStreakCheck: settings.lastStreakCheck,
          isLoading: false,
        );
        _lastKnownDailyGoal = settings.dailyGoal;
      }
    } catch (error) {
      _logger.severe('Error loading settings: $error');
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> updateDailyGoal(int minutes) async {
    try {
      final newGoal = minutes * 60; // Convert minutes to seconds
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        final settings = UserSettings(
          userId: user.id,
          dailyGoal: newGoal,
          streak: state.streak,
          lastStreakCheck: state.lastStreakCheck ?? DateTime.now(),
          updatedAt: DateTime.now(),
          locationName: state.locationName,
        );
        await _ref.read(settingsServiceProvider).updateUserSettings(settings);
        state = state.copyWith(dailyGoal: newGoal);
        _lastKnownDailyGoal = newGoal;
      }
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> updateLocation(String location) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        // First, fetch the current settings from Supabase to ensure we have the latest data
        final currentSettings = await _ref.read(settingsServiceProvider).getUserSettings(user.id);
        
        if (currentSettings == null) {
          _logger.warning('No settings found when updating location');
          return;
        }
        
        // Create updated settings with the new location, preserving the existing daily goal
        final settings = UserSettings(
          userId: user.id,
          dailyGoal: currentSettings.dailyGoal,
          streak: currentSettings.streak,
          lastStreakCheck: currentSettings.lastStreakCheck,
          updatedAt: DateTime.now(),
          locationName: location,
        );
        
        // Update settings in Supabase
        await _ref.read(settingsServiceProvider).updateUserSettings(settings);
        
        // Update local state
        state = state.copyWith(
          locationName: location,
          dailyGoal: currentSettings.dailyGoal,
        );
        _lastKnownDailyGoal = currentSettings.dailyGoal;
      }
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
}); 