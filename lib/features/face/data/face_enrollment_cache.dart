import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local cache for face enrollment lists so the mobile app can display
/// enrollment status even when offline.
class FaceEnrollmentCache {
  FaceEnrollmentCache._();
  static final FaceEnrollmentCache instance = FaceEnrollmentCache._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'face_enrollment_cache.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE enrollment_cache (
            cache_key TEXT PRIMARY KEY,
            json_payload TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      },
      version: 1,
    );
  }

  Future<void> save(String cacheKey, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert(
      'enrollment_cache',
      {
        'cache_key': cacheKey,
        'json_payload': jsonEncode(payload),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> load(String cacheKey) async {
    final db = await database;
    final rows = await db.query(
      'enrollment_cache',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['json_payload'] as String;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('enrollment_cache');
  }
}
