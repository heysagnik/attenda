import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/models/attendance_record.dart';

class LocalStorageService {
  static const String _storageKey = 'attendance_history';

  // Save a new attendance record
  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing records
    List<AttendanceRecord> records = await getAttendanceRecords();

    // Add new record at the beginning
    records.insert(0, record);

    // Save records back to storage
    final jsonList =
        records.map((record) => jsonEncode(record.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  // Get all stored attendance records
  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    // Parse JSON strings to records
    return jsonList.map((jsonString) {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return AttendanceRecord.fromJson(json);
    }).toList();
  }

  // Clear all records (for testing)
  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
