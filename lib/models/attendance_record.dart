class AttendanceRecord {
  final String registrationNo;
  final DateTime timestamp;
  final bool success;
  final String eventName;
  final String id;

  AttendanceRecord({
    required this.registrationNo,
    required this.timestamp,
    required this.success,
    required this.eventName,
    this.id = '',
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      registrationNo: json['registrationNo'] as String? ?? '',
      // Parse the date from an ISO8601 string, or use current time if null
      timestamp: DateTime.parse(
          json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      success: json['success'] as bool? ?? false,
      eventName: json['eventName'] as String? ?? 'Unknown Event',
      id: json['id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'registrationNo': registrationNo,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
        'eventName': eventName,
        'id': id,
      };
}
