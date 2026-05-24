import 'dart:math';
import 'package:flame/components.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/runner_game.dart';
import 'coin_component.dart';

// ignore: deprecated_member_use
class CoinSpawner extends Component with HasGameRef<RunnerGame> {
  final Random _rng = Random();
  double _timer = 0;
  double _interval = 0.9;

  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;
    _timer += dt;
    if (_timer >= _interval) {
      _timer = 0;
      _spawnPattern();
    }
  }

  void _spawnPattern() {
    final lanes = [gameRef.laneLeft, gameRef.laneCenter, gameRef.laneRight];
    final lx = lanes[_rng.nextInt(3)];
    final pattern = _rng.nextInt(4);

    // Spawn above the screen so they enter from the top
    const double baseY = -150;

    switch (pattern) {
      case 0: // Straight vertical row
        for (int i = 0; i < 5; i++) {
          _addCoin(lx, baseY - i * 40.0);
        }
        break;
      case 1: // Small staggered group
        for (int i = 0; i < 4; i++) {
          _addCoin(lx, baseY - i * 50.0);
        }
        break;
      case 2: // Two lanes staggered
        final lx2 = lanes[_rng.nextInt(3)];
        for (int i = 0; i < 3; i++) {
          _addCoin(lx, baseY - i * 40.0);
          _addCoin(lx2, baseY - 120 - i * 40.0);
        }
        break;
      case 3: // Zigzag vertical
        final lx2 = lanes[_rng.nextInt(3)];
        for (int i = 0; i < 6; i++) {
          _addCoin(i.isEven ? lx : lx2, baseY - i * 60.0);
        }
        break;
    }
  }

  int _getLaneIndex(double x) {
    if ((x - gameRef.laneLeft).abs() < 10) return 0;
    if ((x - gameRef.laneCenter).abs() < 10) return 1;
    return 2;
  }

  void _addCoin(double laneX, double y) {
    final laneIndex = _getLaneIndex(laneX);
    const h = 35.0; // coin height

    // Strict lane reservation check - covers ALL objects (buses, hurdles, etc)
    if (!gameRef.isLaneClear(laneIndex, y, h)) return;

    final pos = Vector2(laneX - 17, y);
    gameRef.add(CoinComponent(position: pos));
    gameRef.reserveLane(laneIndex, y + h);
  }

  void reset() {
    _timer = 0;
    _interval = 0.9;
    gameRef.children
        .whereType<CoinComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());
  }
}
