class TimeEntry {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final DateTime date;
  final bool isManual;

  TimeEntry({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.date,
    this.isManual = false,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      duration: json['duration'] as int,
      date: DateTime.parse(json['date'] as String),
      isManual: json['isManual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'date': date.toIso8601String(),
      'isManual': isManual,
    };
  }

  TimeEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    DateTime? date,
    bool? isManual,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      isManual: isManual ?? this.isManual,
    );
  }
} 