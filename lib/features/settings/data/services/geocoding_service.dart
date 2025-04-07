import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Convert a location name to coordinates
  /// Returns a map with 'latitude' and 'longitude' keys, or null if geocoding failed
  Future<Map<String, double>?> getCoordinatesFromLocation(String locationName) async {
    try {
      final locations = await locationFromAddress(locationName);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error geocoding location: $e');
      return null;
    }
  }
} 