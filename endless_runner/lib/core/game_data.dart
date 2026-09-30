import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'difficulty.dart';
import 'missions.dart';

class GameData {
  static final GameData _instance = GameData._internal();
  factory GameData() => _instance;
  GameData._internal();

  int coins = 2000;
  int gems = 30;
  int highScore = 0;
  int selectedCharacter = 0;
  int magnetLevel = 1;
  int shieldLevel = 1;
  int speedLevel = 1;
  List<bool> unlockedCharacters = [true, false, false, false];
  bool musicEnabled = true;
  bool sfxEnabled = true;

  String nickname = "Player";

  // Daily reward — stores the local date (yyyy-mm-dd) of the last claim
  static const int dailyRewardAmount = 1000;
  String lastDailyRewardDate = '';

  // Missions — progress resets each time the player moves up a tier
  int missionTier = 1;
  List<int> missionProgress = List.filled(Missions.all.length, 0);
  List<bool> missionClaimed = List.filled(Missions.all.length, false);

  static const int maxPowerUpLevel = 5;
  static const int baseUpgradeCost = 500;

  int getUpgradeCost(int currentLevel) {
    return currentLevel * baseUpgradeCost;
  }

  static const List<int> characterCosts = [0, 2000, 3000, 5000];
  static const List<String> characterNames = ['BOY', 'GIRL', 'NINJA', 'ROBOT'];
  static const List<Color> characterBodyColors = [
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF212121),
    Color(0xFF607D8B),
  ];
  static const List<Color> characterSkinColors = [
    Color(0xFFFFC299),
    Color(0xFFFFC299),
    Color(0xFF212121),
    Color(0xFF90A4AE),
  ];

  // Character stats (Ability multipliers)
  static const List<double> characterJumpMultiplier = [1.0, 1.0, 1.25, 0.95];
  static const List<double> characterSpeedMultiplier = [1.0, 1.1, 1.0, 1.2];

  // ── Persistence ──────────────────────────────────────────────────────────
  // Phone: SQLite via DatabaseService. Web: SharedPreferences fallback.
  // Older installs saved to SharedPreferences; that data is copied into the
  // database once, on the first launch after the update.

  Future<void>? _loading;
  Future<void> _saveQueue = Future.value();

  /// Loads saved data once per app session. Later calls reuse the first
  /// load, so a reload can never overwrite changes that are still saving.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    if (!DatabaseService.isSupported) return _loadFromPrefs();
    try {
      final dbService = DatabaseService();
      final profile = await dbService.loadProfile();
      if (profile == null) {
        // First launch with the database: migrate old SharedPreferences data
        await _loadFromPrefs();
        await _saveToDb();
        return;
      }
      coins = profile['coins'] as int;
      gems = profile['gems'] as int;
      highScore = profile['high_score'] as int;
      selectedCharacter = profile['selected_character'] as int;
      magnetLevel = profile['magnet_level'] as int;
      shieldLevel = profile['shield_level'] as int;
      speedLevel = profile['speed_level'] as int;
      nickname = profile['nickname'] as String;
      musicEnabled = (profile['music_enabled'] as int) == 1;
      sfxEnabled = (profile['sfx_enabled'] as int) == 1;
      lastDailyRewardDate = profile['last_daily_reward'] as String;
      missionTier = profile['mission_tier'] as int;

      final chars = await dbService.loadCharacters();
      unlockedCharacters = List.generate(
        characterNames.length,
        (i) => i == 0 || (i < chars.length && chars[i]),
      );

      final missionRows = await dbService.loadMissions();
      missionProgress = List.filled(Missions.all.length, 0);
      missionClaimed = List.filled(Missions.all.length, false);
      for (final row in missionRows) {
        final slot = row['slot'] as int;
        if (slot >= Missions.all.length) continue;
        missionProgress[slot] = row['progress'] as int;
        missionClaimed[slot] = (row['claimed'] as int) == 1;
      }
    } catch (e) {
      // Never block the game on storage; fall back to the old store
      debugPrint('Database load failed, using SharedPreferences: $e');
      await _loadFromPrefs();
    }
  }

  /// Saves everything. Saves run one after another in call order.
  Future<void> save() {
    return _saveQueue = _saveQueue.then((_) async {
      try {
        if (DatabaseService.isSupported) {
          await _saveToDb();
        } else {
          await _saveToPrefs();
        }
      } catch (e) {
        debugPrint('Save failed: $e');
      }
    });
  }

  Future<void> _saveToDb() {
    return DatabaseService().saveAll(
      profile: {
        'coins': coins,
        'gems': gems,
        'high_score': highScore,
        'selected_character': selectedCharacter,
        'magnet_level': magnetLevel,
        'shield_level': shieldLevel,
        'speed_level': speedLevel,
        'nickname': nickname,
        'music_enabled': musicEnabled ? 1 : 0,
        'sfx_enabled': sfxEnabled ? 1 : 0,
        'last_daily_reward': lastDailyRewardDate,
        'mission_tier': missionTier,
      },
      characters: unlockedCharacters,
      missionProgress: missionProgress,
      missionClaimed: missionClaimed,
    );
  }

  // ── Runs (Top 10) ────────────────────────────────────────────────────────

  /// Stores a finished run for the Top Runs screen.
  Future<void> recordRun({
    required int score,
    required int coinsCollected,
  }) async {
    if (!DatabaseService.isSupported || score <= 0) return;
    final run = RunRecord(
      score: score,
      distance: score ~/ Missions.scorePerMeter,
      coins: coinsCollected,
      character: selectedCharacter,
      playedAt: DateTime.now(),
    );
    _runWrite = _runWrite.then((_) async {
      try {
        await DatabaseService().insertRun(run);
      } catch (e) {
        debugPrint('Recording run failed: $e');
      }
    });
    await _runWrite;
  }

  // Pending run insert, so reads right after a game over include that run
  Future<void> _runWrite = Future.value();

  /// Recent run scores, oldest first — input for difficulty adjustment.
  Future<List<int>> recentRunScores() async {
    if (!DatabaseService.isSupported) return [];
    try {
      await _runWrite;
      return await DatabaseService()
          .recentRunScores(limit: DifficultyAdjuster.sampleSize);
    } catch (e) {
      debugPrint('Loading recent runs failed: $e');
      return [];
    }
  }

  Future<List<RunRecord>> topRuns() async {
    if (!DatabaseService.isSupported) return [];
    try {
      return await DatabaseService().topRuns(limit: 10);
    } catch (e) {
      debugPrint('Loading top runs failed: $e');
      return [];
    }
  }

  /// Resets the high score and clears the run history.
  Future<void> resetHighScore() async {
    highScore = 0;
    await save();
    if (!DatabaseService.isSupported) return;
    try {
      await DatabaseService().clearRuns();
    } catch (e) {
      debugPrint('Clearing runs failed: $e');
    }
  }

  // ── SharedPreferences (legacy / web) ─────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt('coins') ?? 2000;
    gems = prefs.getInt('gems') ?? 30;
    highScore = prefs.getInt('high_score') ?? 0;
    selectedCharacter = prefs.getInt('selected_character') ?? 0;
    magnetLevel = prefs.getInt('magnetLevel') ?? 1;
    shieldLevel = prefs.getInt('shieldLevel') ?? 1;
    speedLevel = prefs.getInt('speedLevel') ?? 1;
    nickname = prefs.getString('nickname') ?? "Player";
    lastDailyRewardDate = prefs.getString('last_daily_reward') ?? '';
    missionTier = prefs.getInt('mission_tier') ?? 1;
    final progress = prefs.getStringList('mission_progress');
    final claimed = prefs.getStringList('mission_claimed');
    missionProgress = List.generate(
      Missions.all.length,
      (i) => progress != null && i < progress.length
          ? int.tryParse(progress[i]) ?? 0
          : 0,
    );
    missionClaimed = List.generate(
      Missions.all.length,
      (i) => claimed != null && i < claimed.length && claimed[i] == 'true',
    );
    final unlocked =
        prefs.getStringList('unlocked') ?? ['true', 'false', 'false', 'false'];
    unlockedCharacters = unlocked.map((e) => e == 'true').toList();
    musicEnabled = prefs.getBool('musicEnabled') ?? true;
    sfxEnabled = prefs.getBool('sfxEnabled') ?? true;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins);
    await prefs.setInt('gems', gems);
    await prefs.setInt('high_score', highScore);
    await prefs.setInt('selected_character', selectedCharacter);
    await prefs.setInt('magnetLevel', magnetLevel);
    await prefs.setInt('shieldLevel', shieldLevel);
    await prefs.setInt('speedLevel', speedLevel);
    await prefs.setString('nickname', nickname);
    await prefs.setString('last_daily_reward', lastDailyRewardDate);
    await prefs.setInt('mission_tier', missionTier);
    await prefs.setStringList(
      'mission_progress',
      missionProgress.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'mission_claimed',
      missionClaimed.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'unlocked',
      unlockedCharacters.map((e) => e.toString()).toList(),
    );
    await prefs.setBool('musicEnabled', musicEnabled);
    await prefs.setBool('sfxEnabled', sfxEnabled);
  }

  Future<void> updateHighScore(int score) async {
    if (score > highScore) {
      highScore = score;
      await save();
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool get canClaimDailyReward => lastDailyRewardDate != _todayKey();

  bool claimDailyReward() {
    if (!canClaimDailyReward) return false;
    coins += dailyRewardAmount;
    lastDailyRewardDate = _todayKey();
    save();
    return true;
  }

  // ── Missions ─────────────────────────────────────────────────────────────
  int get missionReward => Missions.rewardForTier(missionTier);

  int missionTarget(int index) =>
      Missions.targetFor(Missions.all[index], missionTier);

  bool isMissionComplete(int index) =>
      missionProgress[index] >= missionTarget(index);

  bool canClaimMission(int index) =>
      isMissionComplete(index) && !missionClaimed[index];

  bool get hasClaimableMission =>
      List.generate(Missions.all.length, canClaimMission).any((c) => c);

  /// Adds to a counter mission (coins, dodge, jump, slide, power-ups).
  /// Kept in memory; persisted on the next save().
  void addMissionProgress(MissionType type, [int amount = 1]) {
    final i = Missions.all.indexWhere((m) => m.type == type);
    if (i < 0 || missionClaimed[i]) return;
    missionProgress[i] =
        (missionProgress[i] + amount).clamp(0, missionTarget(i));
  }

  /// Distance mission tracks the best single run, not a running total.
  void recordMissionDistance(int meters) {
    final i = Missions.all.indexWhere((m) => m.type == MissionType.distance);
    if (i < 0 || missionClaimed[i]) return;
    if (meters > missionProgress[i]) {
      missionProgress[i] = meters.clamp(0, missionTarget(i));
    }
  }

  /// Claims the gem reward. When every mission in the tier is claimed,
  /// moves to the next tier with doubled targets and fresh progress.
  bool claimMission(int index) {
    if (!canClaimMission(index)) return false;
    gems += missionReward;
    missionClaimed[index] = true;
    if (missionClaimed.every((c) => c)) {
      missionTier++;
      missionProgress = List.filled(Missions.all.length, 0);
      missionClaimed = List.filled(Missions.all.length, false);
    }
    save();
    return true;
  }

  bool buyCharacter(int index) {
    if (coins >= characterCosts[index] && !unlockedCharacters[index]) {
      coins -= characterCosts[index];
      unlockedCharacters[index] = true;
      save();
      return true;
    }
    return false;
  }
}
