import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationCache {
  final Map<String, Map<String, double>> _cache = {};
  final Duration _cacheDuration;
  
  LocationCache({Duration? cacheDuration}) 
    : _cacheDuration = cacheDuration ?? const Duration(hours: 24);
  
  Map<String, double>? getCoordinates(String locationName) {
    final cached = _cache[locationName];
    if (cached != null) {
      return cached;
    }
    return null;
  }
  
  void cacheCoordinates(String locationName, Map<String, double> coordinates) {
    _cache[locationName] = coordinates;
  }
  
  void clearCache() {
    _cache.clear();
  }
}

final locationCacheProvider = Provider((ref) => LocationCache()); 