import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:runner_rush/features/obstacles/coin_spawnner.dart';
import 'package:runner_rush/features/obstacles/hud_component.dart';
import 'package:runner_rush/features/obstacles/obstacle_spawnner.dart';
import 'package:runner_rush/features/obstacles/powerup_spawner.dart';
import 'package:runner_rush/features/obstacles/road_component.dart';
import 'package:runner_rush/features/player/player_component.dart';

import 'package:runner_rush/services/audio_service.dart';

import 'core/game_data.dart';
import 'core/game_state.dart';
import 'core/missions.dart';

class RunnerGame extends FlameGame
    // ignore: deprecated_member_use
    with
        HasCollisionDetection,
        PanDetector,
        TapCallbacks {
  RunnerGameState gameState = RunnerGameState.menu;
  final scoreNotifier = ValueNotifier<int>(0);
  final coinsNotifier = ValueNotifier<int>(0);

  int get score => scoreNotifier.value;
  set score(int v) {
    if (scoreNotifier.value == v) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        scoreNotifier.value = v;
      });
    } else {
      scoreNotifier.value = v;
    }
  }

  int get coinsCollected => coinsNotifier.value;
  set coinsCollected(int v) {
    if (coinsNotifier.value == v) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        coinsNotifier.value = v;
      });
    } else {
      coinsNotifier.value = v;
    }
  }

  double worldSpeed = 6.0;

  // Lane Reservation System to prevent overlaps
  // Stores the lowest Y position (top-most in negative Y space) of the last spawned object per lane
  final Map<int, double> _laneOccupiedUntil = {0: 10000, 1: 10000, 2: 10000};

  late double laneLeft;
  late double laneCenter;
  late double laneRight;
  late double groundY;

  late PlayerComponent player;
  late ObstacleSpawner obstacleSpawner;
  late CoinSpawner coinSpawner;
  late PowerUpSpawner powerUpSpawner;
  late HudComponent hud;

  VoidCallback? onGameOver;

  Vector2? _panStart;
  static const double _swipeThreshold = 20.0;
  bool _panHandled = false;

  double _shakeTime = 0;
  int _lastSpeedStep = 0;
  double _elapsedSecs = 0;
  double get elapsedSecs => _elapsedSecs;
  double _scoreAccumulator = 0;

  @override
  Color backgroundColor() => const Color(0xFF0D1B2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await GameData().load();
    await AudioService().init();
    AudioService().playBgm();

    groundY = size.y * 0.88;
    laneLeft = size.x * 0.22;
    laneCenter = size.x * 0.50;
    laneRight = size.x * 0.78;

    await add(RoadComponent());

    player = PlayerComponent();
    await add(player);

    obstacleSpawner = ObstacleSpawner();
    coinSpawner = CoinSpawner();
    powerUpSpawner = PowerUpSpawner();
    await add(obstacleSpawner);
    await add(coinSpawner);
    await add(powerUpSpawner);

    hud = HudComponent();
    await add(hud);

    gameState = RunnerGameState.playing;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedSecs += dt;
    if (gameState != RunnerGameState.playing) return;

    // Throttled score: ~60 points/sec regardless of frame rate
    _scoreAccumulator += dt * 60;
    if (_scoreAccumulator >= 1.0) {
      final points = _scoreAccumulator.toInt();
      _scoreAccumulator -= points;
      score += points;
      GameData().recordMissionDistance(score ~/ Missions.scorePerMeter);
    }

    final speedMult =
        GameData.characterSpeedMultiplier[GameData().selectedCharacter];

    // Stepped speed increase every 2500 points
    final speedStep = score ~/ 2500;
    double baseSpeed = 5.5 + (speedStep * 1.5);
    worldSpeed =
        baseSpeed.clamp(5.5, 20.0) * speedMult * player.speedMultiplier;

    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final amp = _shakeTime * 12;
      final even = (_shakeTime * 100).toInt().isEven;
      camera.viewfinder.position = Vector2(
        size.x / 2 + (even ? amp : -amp),
        size.y / 2 + (even ? amp * 0.4 : -amp * 0.4),
      );
    } else {
      camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
    }

    // Only update audio pitch when a new speed milestone is reached
    if (speedStep != _lastSpeedStep) {
      _lastSpeedStep = speedStep;
      AudioService().updateBgmPitch(worldSpeed);
    }

    // Move the lane reservations down with the world (clamped to prevent drift)
    _laneOccupiedUntil
        .updateAll((k, v) => (v + worldSpeed).clamp(-10000.0, size.y + 500));
  }

  // ── Input ────────────────────────────────────────────────────────────────
  @override
  void onPanStart(DragStartInfo info) {
    _panStart = info.eventPosition.global;
    _panHandled = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_panHandled || _panStart == null) return;
    final delta = info.eventPosition.global - _panStart!;
    if (delta.length < _swipeThreshold) return;
    _panHandled = true;
    _panStart = null;
    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x > 0) {
        player.moveRight();
      } else {
        player.moveLeft();
      }
    } else {
      if (delta.y < 0) {
        player.jump();
      } else {
        player.slide();
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _panStart = null;
    _panHandled = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Jump restricted to swipe up (handled in onPanUpdate)
  }

  // ── Public API ───────────────────────────────────────────────────────────
  void triggerShake() => _shakeTime = 0.25;

  void triggerGameOver() {
    if (gameState == RunnerGameState.gameOver) return;
    gameState = RunnerGameState.gameOver;
    GameData().updateHighScore(score);
    // Add collected coins to global total only at the end of the run
    GameData().coins += coinsCollected;
    GameData().save();
    AudioService().stopBgm();
    AudioService().playSfx('crash.wav');
    onGameOver?.call();
  }

  void collectCoin() {
    coinsCollected++;
    GameData().addMissionProgress(MissionType.coins);
  }

  /// Checks if a lane is safe to spawn at a specific Y position
  bool isLaneClear(int laneIndex, double y, double height) {
    final occupiedUntil = _laneOccupiedUntil[laneIndex] ?? 10000.0;
    // We need a buffer of at least 100px between any objects
    // Objects are 'above' (smaller Y) if they are further back
    return (y + height) < (occupiedUntil - 100);
  }

  /// Mark a lane as occupied until a certain Y position
  void reserveLane(int laneIndex, double bottomY) {
    _laneOccupiedUntil[laneIndex] = bottomY;
  }

  void pauseGame() {
    gameState = RunnerGameState.paused;
    pauseEngine();
  }

  void resumeGame() {
    gameState = RunnerGameState.playing;
    resumeEngine();
  }

  void restartGame() {
    scoreNotifier.value = 0;
    coinsNotifier.value = 0;
    worldSpeed = 6.0;
    _shakeTime = 0;
    _elapsedSecs = 0;
    _lastSpeedStep = 0;
    _scoreAccumulator = 0;
    player.reset();
    obstacleSpawner.reset();
    coinSpawner.reset();
    powerUpSpawner.reset();
    _laneOccupiedUntil[0] = 10000;
    _laneOccupiedUntil[1] = 10000;
    _laneOccupiedUntil[2] = 10000;
    AudioService().playBgm();
    gameState = RunnerGameState.playing;
    resumeEngine();
  }
}
