import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/location_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/providers/geocoding_provider.dart';
import '../../../settings/presentation/providers/location_cache_provider.dart';
import '../../data/services/sunset_service.dart';

final sunsetServiceProvider = Provider((ref) => SunsetService());

/// Provider that fetches sunset time based on user's location
final sunsetProvider = FutureProvider<String>((ref) async {
  final locationState = ref.watch(locationProvider);
  final settings = ref.watch(settingsProvider);
  final sunsetService = ref.watch(sunsetServiceProvider);
  final geocodingService = ref.watch(geocodingServiceProvider);
  final locationCache = ref.watch(locationCacheProvider);
  
  // If we have a manual location set in settings, use it first
  if (settings.locationName.isNotEmpty) {
    try {
      // Check cache first
      final cachedCoordinates = locationCache.getCoordinates(settings.locationName);
      
      Map<String, double>? coordinates;
      if (cachedCoordinates != null) {
        coordinates = cachedCoordinates;
      } else {
        // Convert location name to coordinates
        coordinates = await geocodingService.getCoordinatesFromLocation(settings.locationName);
        
        // Cache the coordinates if we got them
        if (coordinates != null) {
          locationCache.cacheCoordinates(settings.locationName, coordinates);
        }
      }
      
      if (coordinates != null) {
        final latitude = coordinates['latitude']!;
        final longitude = coordinates['longitude']!;
        
        // Get sunset time for the manual location
        return await sunsetService.getSunsetTime(latitude, longitude);
      } else {
        print('Could not geocode location: ${settings.locationName}');
      }
    } catch (e) {
      print('Error getting sunset time from manual location: $e');
    }
  }
  
  // If no manual location or it failed, try device location
  if (locationState.position != null) {
    try {
      final latitude = locationState.position!.latitude;
      final longitude = locationState.position!.longitude;
      
      // Get sunset time for the current location
      return await sunsetService.getSunsetTime(latitude, longitude);
    } catch (e) {
      print('Error getting sunset time from device location: $e');
    }
  }
  
  // If no location available, use the default time
  return '7:30 PM';
}); 