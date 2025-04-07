import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

/// A class to represent a location suggestion
class LocationSuggestion {
  final String city;
  final String state;
  final String displayName;

  LocationSuggestion({
    required this.city,
    required this.state,
  }) : displayName = '$city, $state';

  @override
  String toString() => displayName;
}

/// A notifier that manages location suggestions state
class LocationSuggestionsNotifier extends StateNotifier<AsyncValue<List<LocationSuggestion>>> {
  final Ref _ref;
  Timer? _debounceTimer;
  List<LocationSuggestion> _cachedSuggestions = [];

  LocationSuggestionsNotifier(this._ref) : super(const AsyncValue.data([]));

  /// Clear all suggestions
  void clearSuggestions() {
    state = const AsyncValue.data([]);
    _cachedSuggestions = [];
  }

  /// Search for location suggestions based on user input
  Future<void> searchLocations(String query) async {
    // Cancel any previous debounce timer
    _debounceTimer?.cancel();
    
    // If query is empty, clear suggestions
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      _cachedSuggestions = [];
      return;
    }
    
    // Set loading state
    state = const AsyncValue.loading();
    
    // Debounce the search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // If we have cached suggestions, filter them first
        if (_cachedSuggestions.isNotEmpty) {
          final filteredFromCache = _filterSuggestions(_cachedSuggestions, query);
          if (filteredFromCache.isNotEmpty) {
            state = AsyncValue.data(filteredFromCache);
            return;
          }
        }
        
        // If no cached results or no matches, fetch new suggestions
        final searchQuery = query.trim();
        if (searchQuery.isEmpty) {
          state = const AsyncValue.data([]);
          return;
        }
        
        // Use the geocoding package to search for locations
        final locations = await locationFromAddress(searchQuery);
        
        // Convert to our suggestion model
        final suggestions = await Future.wait(
          locations.map((location) async {
            // Get place details to extract city and state
            final placemarks = await placemarkFromCoordinates(
              location.latitude, 
              location.longitude,
            );
            
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              return LocationSuggestion(
                city: place.locality ?? '',
                state: place.administrativeArea ?? '',
              );
            }
            
            // Fallback if we can't get place details
            return LocationSuggestion(
              city: searchQuery,
              state: '',
            );
          }),
        );
        
        // Cache the suggestions
        _cachedSuggestions = suggestions;
        
        // Filter suggestions
        final filteredSuggestions = _filterSuggestions(suggestions, query);
        
        // Update state with filtered suggestions
        state = AsyncValue.data(filteredSuggestions);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    });
  }

  /// Filter suggestions based on the query
  List<LocationSuggestion> _filterSuggestions(List<LocationSuggestion> suggestions, String query) {
    final queryLower = query.toLowerCase().trim();
    
    return suggestions.where((suggestion) {
      final cityLower = suggestion.city.toLowerCase();
      final stateLower = suggestion.state.toLowerCase();
      final displayLower = suggestion.displayName.toLowerCase();
      
      // Check if the query is a substring of any part
      return cityLower.contains(queryLower) || 
             stateLower.contains(queryLower) ||
             displayLower.contains(queryLower);
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for location suggestions
final locationSuggestionsProvider = StateNotifierProvider<LocationSuggestionsNotifier, AsyncValue<List<LocationSuggestion>>>((ref) {
  return LocationSuggestionsNotifier(ref);
}); 