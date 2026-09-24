import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/call_record.dart';

class CallDatabase {
  CallDatabase._();

  static final CallDatabase instance = CallDatabase._();

  static const String _dbName = 'call_records.db';
  static const String _table = 'calls';

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = join(await getDatabasesPath(), _dbName);
    final opened = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            raw_number TEXT NOT NULL,
            normalized_number TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            status TEXT NOT NULL,
            direction TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL DEFAULT 0,
            reported INTEGER NOT NULL DEFAULT 0,
            report_reason TEXT,
            reported_at INTEGER
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_calls_unique ON $_table '
          '(normalized_number, timestamp, status)',
        );
      },
    );
    _db = opened;
    return opened;
  }

  Future<void> insertIfAbsent(CallRecord record) async {
    final db = await _database;
    final values = record.toMap()..remove('id');
    await db.insert(
      _table,
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<CallRecord>> all() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'timestamp DESC');
    return rows.map(CallRecord.fromMap).toList();
  }

  Future<void> setReported(
    int id, {
    required bool reported,
    String? reason,
  }) async {
    final db = await _database;
    await db.update(
      _table,
      {
        'reported': reported ? 1 : 0,
        'report_reason': reported ? reason : null,
        'reported_at':
            reported ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
