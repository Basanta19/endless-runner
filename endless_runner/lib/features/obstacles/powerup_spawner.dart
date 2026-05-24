import 'dart:math';
import 'package:flame/components.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/runner_game.dart';
import 'powerup_component.dart';
import 'obstacle_component.dart';

// ignore: deprecated_member_use
class PowerUpSpawner extends Component with HasGameRef<RunnerGame> {
  final Random _rng = Random();
  double _timer = 0;
  final double _interval = 10.0; // Guaranteed attempt every 10 seconds

  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;

    _timer += dt;
    if (_timer >= _interval) {
      _timer = 0;
      _spawnPowerUp();
    }
  }

  void _spawnPowerUp() {
    final lanes = [gameRef.laneLeft, gameRef.laneCenter, gameRef.laneRight];
    final lx = lanes[_rng.nextInt(3)];
    final pos = Vector2(lx - 27, -150); // Center adjusted for size 55

    // Avoid spawning inside obstacles
    final obstacles = gameRef.children.whereType<ObstacleComponent>();
    for (final obs in obstacles) {
      // Check if centered in the same lane (lx is the lane center)
      final obsCenter = obs.position.x + obs.size.x / 2;
      final sameLane = (obsCenter - lx).abs() < 10;

      if (sameLane) {
        // Calculate safe Y distance based on obstacle height
        final safeDist = (obs.size.y / 2) + 120; // Increased buffer for safety
        const powerUpCenterY = -150 + 27;
        final obsCenterY = obs.position.y + obs.size.y / 2;

        if ((powerUpCenterY - obsCenterY).abs() < safeDist) {
          return; // Skip this powerup attempt - too close to obstacle
        }
      }
    }

    // Randomly choose between Magnet, Shield, and Speed Boost
    final types = [PowerUpType.magnet, PowerUpType.shield, PowerUpType.speed];
    final type = types[_rng.nextInt(types.length)];

    final p = PowerUpComponent(
      position: pos,
      type: type,
    );
    gameRef.add(p);
  }

  void reset() {
    _timer = 0;
    gameRef.children
        .whereType<PowerUpComponent>()
        .toList()
        .forEach((p) => p.removeFromParent());
  }
}
