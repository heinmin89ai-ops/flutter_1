import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'sync_queue_item.dart';

class SqliteSyncQueue {
  SqliteSyncQueue({Database? database}) : _database = database;

  Database? _database;
  final _uuid = const Uuid();

  Future<void> initialize() async {
    if (_database != null) return;
    final databasePath = path.join(await getDatabasesPath(), 'workshop_ops.db');
    _database = await openDatabase(databasePath, version: 1, onOpen: (database) async {
      await database.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id TEXT PRIMARY KEY,
          shopId TEXT NOT NULL,
          entityType TEXT NOT NULL,
          entityId TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          retryCount INTEGER NOT NULL,
          lastAttemptAt TEXT,
          status TEXT NOT NULL,
          errorMessage TEXT
        )
      ''');
      await database.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status, createdAt)');
      await database.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_queue_idempotency ON sync_queue(entityType, entityId, operation) WHERE status != \'COMPLETED\'');
    });
  }

  Future<void> enqueue({required String shopId, required String entityType, required String entityId, required SyncOperation operation, required Map<String, Object?> payload}) async {
    _requireDatabase();
    await _database!.insert('sync_queue', {
      'id': _uuid.v4(), 'shopId': shopId, 'entityType': entityType, 'entityId': entityId, 'operation': operation.name,
      'payload': jsonEncode(payload), 'createdAt': DateTime.now().toUtc().toIso8601String(), 'retryCount': 0,
      'status': SyncQueueStatus.pending.name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<SyncQueueItem>> pending({int limit = 20}) async {
    _requireDatabase();
    final rows = await _database!.query('sync_queue', where: 'status IN (?, ?)', whereArgs: [SyncQueueStatus.pending.name, SyncQueueStatus.failed.name], orderBy: 'createdAt ASC', limit: limit);
    return rows.map((row) {
      final mutable = Map<String, Object?>.from(row);
      mutable['payload'] = jsonDecode(row['payload']! as String);
      return SyncQueueItem.fromMap(mutable);
    }).toList();
  }

  Future<void> markSyncing(String id) async => _update(id, {'status': SyncQueueStatus.syncing.name, 'lastAttemptAt': DateTime.now().toUtc().toIso8601String()});
  Future<void> markCompleted(String id) async => _update(id, {'status': SyncQueueStatus.completed.name, 'errorMessage': null});
  Future<void> markFailed(String id, String message) async {
    _requireDatabase();
    final result = await _database!.rawQuery('SELECT retryCount FROM sync_queue WHERE id = ?', [id]);
    final retryCount = result.isEmpty ? 1 : ((result.first['retryCount'] as int? ?? 0) + 1);
    await _update(id, {'status': SyncQueueStatus.failed.name, 'retryCount': retryCount, 'errorMessage': message});
  }

  Future<void> recoverStaleSyncing() async {
    _requireDatabase();
    await _database!.update('sync_queue', {'status': SyncQueueStatus.failed.name, 'errorMessage': 'Recovered after app restart.'}, where: 'status = ?', whereArgs: [SyncQueueStatus.syncing.name]);
  }

  Future<void> _update(String id, Map<String, Object?> values) async {
    _requireDatabase();
    await _database!.update('sync_queue', values, where: 'id = ?', whereArgs: [id]);
  }

  void _requireDatabase() { if (_database == null) throw StateError('Sync queue has not been initialized.'); }
}
