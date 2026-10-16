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
      version: 2,
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
            reported_at INTEGER,
            trust_score INTEGER,
            trust_rating TEXT,
            trust_checked_at INTEGER
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_calls_unique ON $_table '
          '(normalized_number, timestamp, status)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_table ADD COLUMN trust_score INTEGER');
          await db.execute('ALTER TABLE $_table ADD COLUMN trust_rating TEXT');
          await db
              .execute('ALTER TABLE $_table ADD COLUMN trust_checked_at INTEGER');
        }
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

  Future<void> setReportedByNumber(
    String normalizedNumber, {
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
      where: 'normalized_number = ?',
      whereArgs: [normalizedNumber],
    );
  }

  /// Caches a trust-score result against every row sharing [normalizedNumber],
  /// stamping the check time so the UI can tell a checked number (even a
  /// neutral one) from a never-checked number.
  Future<void> setTrustByNumber(
    String normalizedNumber, {
    required int trustScore,
    required String trustRating,
  }) async {
    final db = await _database;
    await db.update(
      _table,
      {
        'trust_score': trustScore,
        'trust_rating': trustRating,
        'trust_checked_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'normalized_number = ?',
      whereArgs: [normalizedNumber],
    );
  }

  /// Returns the most recent cached trust rating for [normalizedNumber], or
  /// null when the number has never been checked. Used to skip re-checking a
  /// known number on load.
  Future<String?> trustRatingByNumber(String normalizedNumber) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      columns: ['trust_rating'],
      where: 'normalized_number = ? AND trust_rating IS NOT NULL',
      whereArgs: [normalizedNumber],
      orderBy: 'trust_checked_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['trust_rating'] as String?;
  }

  Future<void> deleteById(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
