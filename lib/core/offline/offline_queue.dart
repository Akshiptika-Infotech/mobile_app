import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed queue for actions that must survive app restarts
/// and be replayed when connectivity is restored.
///
/// Typical flow:
///   1. App tries to submit driver attendance → network error.
///   2. Call [enqueue] with the action payload.
///   3. [OfflineSyncService] detects connectivity and calls [dequeuePending].
///   4. For each pending action, the service executes it and calls [markCompleted]
///      or [markFailed] depending on the outcome.
class OfflineQueue {
  OfflineQueue._();
  static final OfflineQueue instance = OfflineQueue._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'offline_queue.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queued_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            idempotency_key TEXT NOT NULL UNIQUE,
            payload TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0,
            error_message TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_status ON queued_actions(status)',
        );
      },
      version: 1,
    );
  }

  /// Enqueues a new action to be replayed later.
  Future<int> enqueue({
    required String actionType,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('queued_actions', {
      'action_type': actionType,
      'idempotency_key': idempotencyKey,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'retry_count': 0,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns all actions with status = 'pending' ordered by creation time.
  Future<List<QueuedAction>> getPending() async {
    final db = await database;
    final rows = await db.query(
      'queued_actions',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(QueuedAction.fromMap).toList();
  }

  /// Marks an action as successfully completed.
  Future<void> markCompleted(int id) async {
    final db = await database;
    await db.delete('queued_actions', where: 'id = ?', whereArgs: [id]);
  }

  /// Marks an action as failed after exhausting retries.
  Future<void> markFailed(int id, String error) async {
    final db = await database;
    await db.update(
      'queued_actions',
      {'status': 'failed', 'error_message': error, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increments retry count and keeps status as pending.
  Future<void> markRetry(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE queued_actions SET retry_count = retry_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Deletes actions older than [days] that are already failed.
  Future<void> pruneFailed({int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    await db.delete(
      'queued_actions',
      where: "status = 'failed' AND updated_at < ?",
      whereArgs: [cutoff],
    );
  }

  /// Returns the count of pending actions (useful for UI badges).
  Future<int> pendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM queued_actions WHERE status = 'pending'",
    );
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }
}

class QueuedAction {
  const QueuedAction({
    required this.id,
    required this.actionType,
    required this.idempotencyKey,
    required this.payload,
    required this.status,
    required this.retryCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String actionType;
  final String idempotencyKey;
  final Map<String, dynamic> payload;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory QueuedAction.fromMap(Map<String, dynamic> map) {
    return QueuedAction(
      id: map['id'] as int,
      actionType: map['action_type'] as String,
      idempotencyKey: map['idempotency_key'] as String,
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      status: map['status'] as String,
      retryCount: map['retry_count'] as int,
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
