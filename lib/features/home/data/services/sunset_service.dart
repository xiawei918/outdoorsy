import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SunsetService {
  static const String baseUrl = 'https://api.sunrise-sunset.org/json';

  /// Fetches the sunset time for the given coordinates
  /// Returns the sunset time in local time zone as a formatted string (e.g. "7:30 PM")
  Future<String> getSunsetTime(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?lat=$latitude&lng=$longitude&formatted=0'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          // Parse the UTC sunset time
          final utcSunset = DateTime.parse(data['results']['sunset']);
          
          // Convert to local time
          final localSunset = utcSunset.toLocal();
          
          // Format the time as HH:mm AM/PM
          final formatter = DateFormat('h:mm a');
          return formatter.format(localSunset);
        }
      }
      throw Exception('Failed to fetch sunset time');
    } catch (e) {
      print('Error fetching sunset time: $e');
      // todo: handle when sunset service is not available
      return '7:30 PM'; // Fallback time
    }
  }
} 