import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:runner_rush/core/database_service.dart';
import 'package:runner_rush/core/game_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Start from an empty database
    final path = p.join(await getDatabasesPath(), 'runner_rush.db');
    if (File(path).existsSync()) File(path).deleteSync();
  });

  test('old SharedPreferences data migrates into the database', () async {
    // What an existing player's phone has before the update
    SharedPreferences.setMockInitialValues({
      'coins': 4321,
      'gems': 55,
      'high_score': 9000,
      'selected_character': 2,
      'magnetLevel': 3,
      'nickname': 'basanta',
      'unlocked': ['true', 'false', 'true', 'false'],
      'mission_tier': 2,
      'mission_progress': ['500', '10', '0', '0', '0', '0'],
      'mission_claimed': ['true', 'false', 'false', 'false', 'false', 'false'],
      'last_daily_reward': '2026-09-29',
    });

    final gd = GameData();
    await gd.load();

    expect(gd.coins, 4321);
    expect(gd.gems, 55);
    expect(gd.highScore, 9000);
    expect(gd.selectedCharacter, 2);
    expect(gd.magnetLevel, 3);
    expect(gd.nickname, 'basanta');
    expect(gd.unlockedCharacters, [true, false, true, false]);
    expect(gd.missionTier, 2);
    expect(gd.missionProgress.first, 500);
    expect(gd.missionClaimed.first, true);

    // And it was written into the database
    final profile = await DatabaseService().loadProfile();
    expect(profile, isNotNull);
    expect(profile!['coins'], 4321);
    expect(profile['nickname'], 'basanta');
  });

  test('saves go to the database in order', () async {
    final gd = GameData();
    gd.coins = 100;
    gd.save();
    gd.coins = 200;
    gd.unlockedCharacters[3] = true;
    gd.missionProgress[1] = 42;
    await gd.save();

    final profile = await DatabaseService().loadProfile();
    expect(profile!['coins'], 200); // last save wins
    expect(await DatabaseService().loadCharacters(), [true, false, true, true]);
    final missions = await DatabaseService().loadMissions();
    expect(missions[1]['progress'], 42);
  });

  test('top runs are the 10 best, highest first', () async {
    final gd = GameData();
    for (final score in [300, 12000, 50, 7000, 900, 0]) {
      await gd.recordRun(score: score, coinsCollected: score ~/ 100);
    }
    for (int i = 0; i < 10; i++) {
      await gd.recordRun(score: 1000 + i, coinsCollected: 1);
    }

    final top = await gd.topRuns();
    expect(top.length, 10);
    expect(top.first.score, 12000);
    expect(top.first.distance, 1200); // 10 score points per meter
    expect(top.first.coins, 120);
    expect(top[1].score, 7000);
    // Sorted high to low, and a 0-score run is never stored
    for (int i = 1; i < top.length; i++) {
      expect(top[i - 1].score >= top[i].score, isTrue);
    }
    expect(top.any((r) => r.score == 0), isFalse);
  });

  test('reset high score clears runs', () async {
    final gd = GameData();
    await gd.resetHighScore();
    expect(gd.highScore, 0);
    expect(await gd.topRuns(), isEmpty);
    expect((await DatabaseService().loadProfile())!['high_score'], 0);
  });
}
