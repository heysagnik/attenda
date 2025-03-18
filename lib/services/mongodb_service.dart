import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance/models/attendance_record.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MongoDBService {
  static MongoDBService? _instance;
  Db? _db;
  bool _isInitialized = false;
  final LocalStorageService _localStorageService = LocalStorageService();
  String? _currentCollection;

  final String _mongoUrl;
  final String _username;
  final String _password;
  final String _databaseName = 'attendance';

  MongoDBService._({
    required String mongoUrl,
    required String username,
    required String password,
  })  : _mongoUrl = mongoUrl,
        _username = username,
        _password = password;

  factory MongoDBService({
    required String mongoUrl,
    required String username,
    required String password,
  }) {
    _instance ??= MongoDBService._(
      mongoUrl: mongoUrl,
      username: username,
      password: password,
    );
    return _instance!;
  }

  String? get currentCollection => _currentCollection;

  Future<void> setCurrentCollection(String collectionName) async {
    _currentCollection = collectionName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_collection', collectionName);
  }

  Future<String?> loadSavedCollection() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCollection = prefs.getString('selected_collection');
    return _currentCollection;
  }

  Future<List<String>> getCollectionNames() async {
    await initialize();
    try {
      final collections = await _db!.getCollectionNames();
      return collections
          .where((name) =>
              name != null &&
              !name.startsWith('system.') &&
              name != 'attendance_history')
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching collection names: $e');
      return [];
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final String connectionString =
          'mongodb+srv://$_username:$_password@$_mongoUrl/$_databaseName?retryWrites=true&w=majority';
      _db = await Db.create(connectionString);
      await _db!.open();
      _isInitialized = true;
      debugPrint('Connected to MongoDB successfully');
    } catch (e) {
      debugPrint('Failed to connect to MongoDB: $e');
      rethrow;
    }
  }

  Future<bool> isStudentRegistered(String registrationNo) async {
    if (_currentCollection == null) {
      throw Exception("No collection selected");
    }
    await initialize();
    try {
      final collection = _db!.collection(_currentCollection!);
      final student =
          await collection.findOne(where.eq('registrationNo', registrationNo));
      return student != null;
    } catch (e) {
      debugPrint('Error checking student registration: $e');
      return false;
    }
  }

  Future<bool> isStudentPresent(String registrationNo) async {
    if (_currentCollection == null) {
      throw Exception("No collection selected");
    }
    await initialize();
    try {
      final collection = _db!.collection(_currentCollection!);
      final student =
          await collection.findOne(where.eq('registrationNo', registrationNo));
      return (student?['verified'] as bool?) ?? false;
    } catch (e) {
      debugPrint('Error checking student presence on server: $e');
      return false;
    }
  }

  Future<bool> markStudentPresent(
      String registrationNo, String eventName) async {
    if (_currentCollection == null) {
      throw Exception("No collection selected");
    }
    await initialize();
    final collection = _db!.collection(_currentCollection!);
    final student =
        await collection.findOne(where.eq('registrationNo', registrationNo));
    if (student == null) {
      debugPrint(
          'Student [$registrationNo] not found. Cannot mark as present.');
      return false;
    }
    try {
      await collection.updateOne(
        where.eq('registrationNo', registrationNo),
        modify.set('verified', true).set('verifiedAt', DateTime.now()),
      );
    } catch (e) {
      debugPrint('Error marking student present on server: $e');
    }

    final record = AttendanceRecord(
      registrationNo: registrationNo,
      timestamp: DateTime.now(),
      success: true,
      eventName: eventName,
    );
    await _localStorageService.saveAttendanceRecord(record);
    return true;
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(
      {int limit = 50}) async {
    try {
      final localRecords = await _localStorageService.getAttendanceRecords();
      localRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return localRecords
          .map((record) {
            return {
              'registrationNo': record.registrationNo,
              'timestamp': record.timestamp,
              'success': record.success,
              'id': record.id,
              'eventName': record.eventName,
            };
          })
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('Error fetching local attendance records: $e');
      return [];
    }
  }

  Future<void> close() async {
    if (_isInitialized && _db != null) {
      await _db!.close();
      _isInitialized = false;
    }
  }
}
