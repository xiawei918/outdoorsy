import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationState {
  final bool isLocationEnabled;
  final LocationPermission permission;
  final String locationString;
  final Position? position;
  final bool isLoading;
  final String? error;

  LocationState({
    required this.isLocationEnabled,
    required this.permission,
    required this.locationString,
    this.position,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    bool? isLocationEnabled,
    LocationPermission? permission,
    String? locationString,
    Position? position,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      permission: permission ?? this.permission,
      locationString: locationString ?? this.locationString,
      position: position ?? this.position,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final Ref _ref;

  LocationNotifier(this._ref) : super(LocationState(
    isLocationEnabled: false,
    permission: LocationPermission.denied,
    locationString: '',
    isLoading: true,
  )) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final locationService = _ref.read(locationServiceProvider);
      
      // Check if location services are enabled
      final isEnabled = await locationService.isLocationServiceEnabled();
      
      // Check permission
      final permission = await locationService.checkPermission();
      
      // Get location if enabled and permitted
      String locationString = '';
      Position? position;
      if (isEnabled && permission != LocationPermission.denied && 
          permission != LocationPermission.deniedForever) {
        position = await locationService.getCurrentPosition();
        if (position != null) {
          locationString = await locationService.getLocationString();
        }
      }
      
      state = state.copyWith(
        isLocationEnabled: isEnabled,
        permission: permission,
        locationString: locationString,
        position: position,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final locationService = _ref.read(locationServiceProvider);
      final permission = await locationService.requestPermission();
      
      String locationString = '';
      Position? position;
      if (permission != LocationPermission.denied && 
          permission != LocationPermission.deniedForever) {
        position = await locationService.getCurrentPosition();
        if (position != null) {
          locationString = await locationService.getLocationString();
        }
      }
      
      state = state.copyWith(
        permission: permission,
        locationString: locationString,
        position: position,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> refreshLocation() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final locationService = _ref.read(locationServiceProvider);
      
      // Check if location services are enabled
      final isEnabled = await locationService.isLocationServiceEnabled();
      
      // Check permission
      final permission = await locationService.checkPermission();
      
      // Get location if enabled and permitted
      String locationString = '';
      Position? position;
      if (isEnabled && permission != LocationPermission.denied && 
          permission != LocationPermission.deniedForever) {
        position = await locationService.getCurrentPosition();
        if (position != null) {
          locationString = await locationService.getLocationString();
        }
      }
      
      state = state.copyWith(
        isLocationEnabled: isEnabled,
        permission: permission,
        locationString: locationString,
        position: position,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref);
}); 