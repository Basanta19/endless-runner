import '../../core/game_data.dart';

class ScoreController {
  int current = 0;
  int coinsCollected = 0;
  int multiplier = 1;

  void increment() => current += multiplier;

  void collectCoin() {
    coinsCollected++;
    GameData().coins++;
  }

  void reset() {
    current = 0;
    coinsCollected = 0;
    multiplier = 1;
  }

  Future<void> saveHighScore() async {
    await GameData().updateHighScore(current);
  }
}
