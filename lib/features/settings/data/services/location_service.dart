import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  /// Check location permissions
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      print('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      print('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get current location with low accuracy (sufficient for city/state)
  Future<Position?> getCurrentPosition() async {
    try {
      // Use low accuracy for city/state identification
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get city and state from coordinates
  Future<Map<String, String>> getCityAndStateFromCoordinates(double latitude, double longitude) async {
    try {
      // Use a larger radius for geocoding to ensure we get city/state even with low accuracy
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'city': place.locality ?? '',
          'state': place.administrativeArea ?? '',
        };
      }
      
      return {
        'city': '',
        'state': '',
      };
    } catch (e) {
      print('Error getting city and state: $e');
      return {
        'city': '',
        'state': '',
      };
    }
  }

  /// Get location string (city, state)
  Future<String> getLocationString() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return '';
    }

    // Check permission
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return '';
      }
    }

    // Get current position with low accuracy
    final position = await getCurrentPosition();
    if (position == null) {
      return '';
    }

    // Get city and state
    final locationInfo = await getCityAndStateFromCoordinates(
      position.latitude, 
      position.longitude
    );

    final city = locationInfo['city'] ?? '';
    final state = locationInfo['state'] ?? '';

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (city.isNotEmpty) {
      return city;
    } else if (state.isNotEmpty) {
      return state;
    }

    return '';
  }
} 