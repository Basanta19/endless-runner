import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt('coins') ?? 2000;
    gems = prefs.getInt('gems') ?? 30;
    highScore = prefs.getInt('high_score') ?? 0;
    selectedCharacter = prefs.getInt('selected_character') ?? 0;
    magnetLevel = prefs.getInt('magnetLevel') ?? 1;
    shieldLevel = prefs.getInt('shieldLevel') ?? 1;
    speedLevel = prefs.getInt('speedLevel') ?? 1;
    nickname = prefs.getString('nickname') ?? "Player";
    final unlocked =
        prefs.getStringList('unlocked') ?? ['true', 'false', 'false', 'false'];
    unlockedCharacters = unlocked.map((e) => e == 'true').toList();
    musicEnabled = prefs.getBool('musicEnabled') ?? true;
    sfxEnabled = prefs.getBool('sfxEnabled') ?? true;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins);
    await prefs.setInt('gems', gems);
    await prefs.setInt('high_score', highScore);
    await prefs.setInt('selected_character', selectedCharacter);
    await prefs.setInt('magnetLevel', magnetLevel);
    await prefs.setInt('shieldLevel', shieldLevel);
    await prefs.setInt('speedLevel', speedLevel);
    await prefs.setString('nickname', nickname);
    await prefs.setStringList(
      'unlocked',
      unlockedCharacters.map((e) => e.toString()).toList(),
    );
    await prefs.setBool('musicEnabled', musicEnabled);
    await prefs.setBool('sfxEnabled', sfxEnabled);

    // Push to Firebase in the background
    FirebaseService().syncToCloud();
  }

  Future<void> updateHighScore(int score) async {
    if (score > highScore) {
      highScore = score;
      await save();
    }
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
