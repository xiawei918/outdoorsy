import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/mock_data_provider.dart';
import '../../domain/models/user_settings.dart';
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

  SettingsState({
    required this.dailyGoal,
    required this.locationName,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    int? dailyGoal,
    String? locationName,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  bool _isUsingMockData = false;

  SettingsNotifier(this._ref) : super(SettingsState(
    dailyGoal: 0, // Start with 0, will be updated in _initialize
    locationName: '',
    isLoading: true,
  )) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _ref.read(currentUserProvider);
    
    if (user == null) {
      // Use mock data if no user is authenticated
      _isUsingMockData = true;
      final mockData = _ref.read(mockDataProvider);
      Future.microtask(() {
        state = state.copyWith(
          dailyGoal: mockData.dailyGoal,
          locationName: '',
          isLoading: false,
        );
      });
    } else {
      // Use real data for authenticated users
      _isUsingMockData = false;
      await _loadUserSettings(user.id);
    }

    // Listen to auth state changes
    _ref.listen(currentUserProvider, (previous, next) {
      if (next == null) {
        // Switch to mock data when user signs out
        _isUsingMockData = true;
        final mockData = _ref.read(mockDataProvider);
        Future.microtask(() {
          state = state.copyWith(
            dailyGoal: mockData.dailyGoal,
            locationName: '',
            isLoading: false,
          );
        });
      } else {
        // Switch to real data when user signs in
        _isUsingMockData = false;
        _loadUserSettings(next.id);
      }
    });
    
    // Listen to location changes
    _ref.listen(locationProvider, (previous, next) {
      if (next.locationString.isNotEmpty && state.locationName.isEmpty) {
        updateLocation(next.locationString);
      }
    });
  }

  Future<void> _loadUserSettings(String userId) async {
    try {
      print('Loading settings for user: $userId');
      state = state.copyWith(isLoading: true);
      final settings = await _ref.read(settingsServiceProvider).getUserSettings(userId);
      
      if (settings == null) {
        print('No settings found, creating defaults');
        // Create default settings if none exist
        final defaultSettings = UserSettings(
          userId: userId,
          dailyGoal: 30 * 60, // 30 minutes in seconds
          locationName: '',
          updatedAt: DateTime.now(),
        );
        await _ref.read(settingsServiceProvider).updateUserSettings(defaultSettings);
        
        // After creating default settings, load them again to ensure we have the saved values
        final savedSettings = await _ref.read(settingsServiceProvider).getUserSettings(userId);
        if (savedSettings != null) {
          print('Loaded saved settings: ${savedSettings.toJson()}');
          state = state.copyWith(
            dailyGoal: savedSettings.dailyGoal,
            locationName: savedSettings.locationName,
            isLoading: false,
          );
        } else {
          print('Failed to load saved settings, using defaults');
          state = state.copyWith(
            dailyGoal: defaultSettings.dailyGoal,
            locationName: defaultSettings.locationName,
            isLoading: false,
          );
        }
      } else {
        print('Loaded existing settings: ${settings.toJson()}');
        state = state.copyWith(
          dailyGoal: settings.dailyGoal,
          locationName: settings.locationName,
          isLoading: false,
        );
      }
    } catch (error) {
      print('Error loading settings: $error');
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> updateDailyGoal(int minutes) async {
    try {
      final newGoal = minutes * 60; // Convert minutes to seconds
      if (_isUsingMockData) {
        state = state.copyWith(dailyGoal: newGoal);
      } else {
        final user = _ref.read(currentUserProvider);
        if (user != null) {
          final settings = UserSettings(
            userId: user.id,
            dailyGoal: newGoal,
            locationName: state.locationName,
            updatedAt: DateTime.now(),
          );
          await _ref.read(settingsServiceProvider).updateUserSettings(settings);
          state = state.copyWith(dailyGoal: newGoal);
        }
      }
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> updateLocation(String location) async {
    try {
      if (_isUsingMockData) {
        state = state.copyWith(locationName: location);
      } else {
        final user = _ref.read(currentUserProvider);
        if (user != null) {
          final settings = UserSettings(
            userId: user.id,
            dailyGoal: state.dailyGoal,
            locationName: location,
            updatedAt: DateTime.now(),
          );
          await _ref.read(settingsServiceProvider).updateUserSettings(settings);
          state = state.copyWith(locationName: location);
        }
      }
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
}); 