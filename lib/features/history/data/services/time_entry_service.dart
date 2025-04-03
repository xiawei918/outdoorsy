import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/models/time_entry.dart';

class TimeEntryService {
  final _client = SupabaseConfig.client;

  Future<List<TimeEntry>> getTimeEntries(String userId) async {
    try {
      final response = await _client
          .from('time_entries')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      if (response == null) {
        return [];
      }

      if (response is! List) {
        return [];
      }

      final entries = response.map((entry) {
        final json = {
          'id': entry['id']?.toString() ?? '',
          'userId': entry['user_id']?.toString() ?? '',
          'startTime': entry['start_time']?.toString() ?? '',
          'endTime': entry['end_time']?.toString(),
          'duration': (entry['duration'] as num?)?.toInt() ?? 0,
          'date': entry['date']?.toString() ?? '',
          'isManual': entry['is_manual'] as bool? ?? false,
          'createdAt': entry['created_at']?.toString() ?? '',
        };
        return TimeEntry.fromJson(json);
      }).toList();

      return entries;
    } catch (e) {
      return [];
    }
  }

  Future<TimeEntry> addTimeEntry({
    required String userId,
    required DateTime startTime,
    required DateTime date,
    required int duration,
    DateTime? endTime,
    bool isManual = false,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration': duration,
        'date': date.toIso8601String(),
        'is_manual': isManual,
        'created_at': now.toIso8601String(),
      };

      final response = await _client
          .from('time_entries')
          .insert(data)
          .select()
          .single();

      final json = {
        'id': response['id']?.toString() ?? '',
        'userId': response['user_id']?.toString() ?? '',
        'startTime': response['start_time']?.toString() ?? '',
        'endTime': response['end_time']?.toString(),
        'duration': (response['duration'] as num?)?.toInt() ?? 0,
        'date': response['date']?.toString() ?? '',
        'isManual': response['is_manual'] as bool? ?? false,
        'createdAt': response['created_at']?.toString() ?? '',
      };
      return TimeEntry.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTimeEntry(String id) async {
    try {
      await _client
          .from('time_entries')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<TimeEntry> updateTimeEntry({
    required String id,
    required int duration,
  }) async {
    try {
      final response = await _client
          .from('time_entries')
          .update({
            'duration': duration,
          })
          .eq('id', id)
          .select()
          .single();

      final json = {
        'id': response['id']?.toString() ?? '',
        'userId': response['user_id']?.toString() ?? '',
        'startTime': response['start_time']?.toString() ?? '',
        'endTime': response['end_time']?.toString(),
        'duration': (response['duration'] as num?)?.toInt() ?? 0,
        'date': response['date']?.toString() ?? '',
        'isManual': response['is_manual'] as bool? ?? false,
        'createdAt': response['created_at']?.toString() ?? '',
      };
      return TimeEntry.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw Exception('Invalid date format: $value');
  }
} 