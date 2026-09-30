import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Size;
import 'package:runner_rush/core/object_pool.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/runner_game.dart';
import 'obstacle_component.dart';

// ignore: deprecated_member_use
class ObstacleSpawner extends Component with HasGameRef<RunnerGame> {
  final Random _rng = Random();
  final ObjectPool<ObstacleComponent> _pool =
      ObjectPool(ObstacleComponent.new, maxSize: 20);
  final Vector2 _tmpPos = Vector2.zero();
  final Vector2 _tmpSize = Vector2.zero();
  double _timer = 0;
  double _interval = 1.6; // seconds between spawns

  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;
    _timer += dt;
    // Interval shrinks as worldSpeed rises, then dynamic difficulty scales it:
    // easier → obstacles further apart, harder → closer together
    final base = (1.8 - (gameRef.worldSpeed - 5.5) * 0.08).clamp(0.6, 1.8);
    _interval = (base / gameRef.difficulty).clamp(0.5, 2.25);

    if (_timer >= _interval) {
      _timer = 0;
      _spawnPattern();
    }
  }

  void _spawnPattern() {
    final lanes = [gameRef.laneLeft, gameRef.laneCenter, gameRef.laneRight];
    final pattern = _rng.nextInt(6);

    switch (pattern) {
      case 0: // single
        _spawn(lanes[_rng.nextInt(3)], _pickType(), 0);
        break;
      case 1: // two lanes blocked
        lanes.shuffle(_rng);
        _spawn(lanes[0], _pickType(), 0);
        _spawn(lanes[1], _pickType(), 0);
        break;
      case 2: // staggered
        lanes.shuffle(_rng);
        _spawn(lanes[0], _pickType(), 0);
        _spawn(lanes[1], _pickType(), 300); // 300px vertical offset
        break;
      case 3: // hurdle only — must slide
        _spawn(lanes[_rng.nextInt(3)], ObstacleType.hurdle, 0);
        break;
      case 4: // bus
        _spawn(lanes[_rng.nextInt(3)], ObstacleType.bus, 0);
        break;
      case 5:
        _spawn(gameRef.laneCenter, _pickType(), 0);
        break;
    }
  }

  ObstacleType _pickType() {
    // Dynamic difficulty shifts the obstacle mix: harder players meet buses
    // and containers sooner, struggling players get more cones and barriers
    final speed = gameRef.worldSpeed * gameRef.difficulty;
    final roll = _rng.nextInt(10);
    if (speed > 12) {
      return ObstacleType.container;
    }
    if (speed > 9) {
      if (roll < 4) return ObstacleType.bus;
      if (roll < 7) return ObstacleType.container;
      return ObstacleType.cone;
    }
    return roll < 5 ? ObstacleType.barrier : ObstacleType.cone;
  }

  Size _sizeFor(ObstacleType t) {
    switch (t) {
      case ObstacleType.barrier:
        return const Size(78, 78);
      case ObstacleType.container:
        return const Size(90, 100);
      case ObstacleType.bus:
        return const Size(100, 180);
      case ObstacleType.cone:
        return const Size(56, 64);
      case ObstacleType.hurdle:
        return const Size(90, 45);
    }
  }

  int _getLaneIndex(double x) {
    if ((x - gameRef.laneLeft).abs() < 10) return 0;
    if ((x - gameRef.laneCenter).abs() < 10) return 1;
    return 2;
  }

  void _spawn(double laneX, ObstacleType type, double yOffset) {
    final sz = _sizeFor(type);
    final laneIndex = _getLaneIndex(laneX);
    final h = sz.height.toDouble();
    final spawnY = -h - yOffset - 100;

    // Strict lane reservation check
    if (!gameRef.isLaneClear(laneIndex, spawnY, h)) return;

    // Recycled from the pool instead of creating a new obstacle each time
    final obs = _pool.acquire()
      ..reset(
        position: _tmpPos..setValues(laneX - sz.width / 2, spawnY),
        size: _tmpSize..setValues(sz.width, sz.height),
        type: type,
      );
    gameRef.add(obs);
    gameRef.reserveLane(laneIndex, spawnY + h);
  }

  void reset() {
    _timer = 0;
    _interval = 1.6;
    gameRef.children
        .whereType<ObstacleComponent>()
        .toList()
        .forEach((o) => o.removeFromParent());
  }
}
