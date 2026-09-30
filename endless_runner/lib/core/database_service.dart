import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// One finished run, as stored in the `runs` table.
class RunRecord {
  final int score;
  final int distance; // meters
  final int coins;
  final int character; // index into GameData.characterNames
  final DateTime playedAt;

  const RunRecord({
    required this.score,
    required this.distance,
    required this.coins,
    required this.character,
    required this.playedAt,
  });

  factory RunRecord.fromRow(Map<String, Object?> row) => RunRecord(
        score: row['score'] as int,
        distance: row['distance'] as int,
        coins: row['coins'] as int,
        character: row['character'] as int,
        playedAt: DateTime.fromMillisecondsSinceEpoch(row['played_at'] as int),
      );
}

/// Local SQLite database (Android/iOS). All player state lives here.
///
/// Tables:
///  - profile     single row (id = 1): currencies, levels, settings, tiers
///  - characters  one row per character: unlocked or not
///  - missions    one row per mission slot: progress and claimed
///  - runs        one row per finished run (for the Top 10 runs screen)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const _dbName = 'runner_rush.db';
  static const _dbVersion = 1;

  /// SQLite isn't available in the web build; GameData falls back there.
  static bool get isSupported => !kIsWeb;

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            coins INTEGER NOT NULL,
            gems INTEGER NOT NULL,
            high_score INTEGER NOT NULL,
            selected_character INTEGER NOT NULL,
            magnet_level INTEGER NOT NULL,
            shield_level INTEGER NOT NULL,
            speed_level INTEGER NOT NULL,
            nickname TEXT NOT NULL,
            music_enabled INTEGER NOT NULL,
            sfx_enabled INTEGER NOT NULL,
            last_daily_reward TEXT NOT NULL,
            mission_tier INTEGER NOT NULL
          )
        ''');
        batch.execute('''
          CREATE TABLE characters (
            id INTEGER PRIMARY KEY,
            unlocked INTEGER NOT NULL
          )
        ''');
        batch.execute('''
          CREATE TABLE missions (
            slot INTEGER PRIMARY KEY,
            progress INTEGER NOT NULL,
            claimed INTEGER NOT NULL
          )
        ''');
        batch.execute('''
          CREATE TABLE runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            score INTEGER NOT NULL,
            distance INTEGER NOT NULL,
            coins INTEGER NOT NULL,
            character INTEGER NOT NULL,
            played_at INTEGER NOT NULL
          )
        ''');
        batch.execute('CREATE INDEX idx_runs_score ON runs (score DESC)');
        await batch.commit(noResult: true);
      },
    );
  }

  // ── Profile / characters / missions ──────────────────────────────────────

  /// Returns null if nothing has been saved yet (first launch).
  Future<Map<String, Object?>?> loadProfile() async {
    final rows = await (await db).query('profile', where: 'id = 1');
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<bool>> loadCharacters() async {
    final rows = await (await db).query('characters', orderBy: 'id');
    return rows.map((r) => (r['unlocked'] as int) == 1).toList();
  }

  Future<List<Map<String, Object?>>> loadMissions() async =>
      (await db).query('missions', orderBy: 'slot');

  /// Saves the whole player state in one transaction, so a crash mid-save
  /// can never leave half-written data.
  Future<void> saveAll({
    required Map<String, Object?> profile,
    required List<bool> characters,
    required List<int> missionProgress,
    required List<bool> missionClaimed,
  }) async {
    await (await db).transaction((txn) async {
      final batch = txn.batch();
      batch.insert(
        'profile',
        {'id': 1, ...profile},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (int i = 0; i < characters.length; i++) {
        batch.insert(
          'characters',
          {'id': i, 'unlocked': characters[i] ? 1 : 0},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (int i = 0; i < missionProgress.length; i++) {
        batch.insert(
          'missions',
          {
            'slot': i,
            'progress': missionProgress[i],
            'claimed': missionClaimed[i] ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // ── Runs ─────────────────────────────────────────────────────────────────

  Future<void> insertRun(RunRecord run) async {
    await (await db).insert('runs', {
      'score': run.score,
      'distance': run.distance,
      'coins': run.coins,
      'character': run.character,
      'played_at': run.playedAt.millisecondsSinceEpoch,
    });
  }

  Future<List<RunRecord>> topRuns({int limit = 10}) async {
    final rows = await (await db).query(
      'runs',
      orderBy: 'score DESC, played_at ASC',
      limit: limit,
    );
    return rows.map(RunRecord.fromRow).toList();
  }

  /// Scores of the most recent runs, oldest first (for difficulty tuning).
  Future<List<int>> recentRunScores({int limit = 5}) async {
    final rows = await (await db).query(
      'runs',
      columns: ['score'],
      orderBy: 'played_at DESC, id DESC',
      limit: limit,
    );
    return rows.reversed.map((r) => r['score'] as int).toList();
  }

  Future<void> clearRuns() async => (await db).delete('runs');
}
