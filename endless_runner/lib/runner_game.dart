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

  // The exact score lives here; the on-screen badge (scoreNotifier) is only
  // refreshed ~10x/sec so Flutter doesn't rebuild the HUD every frame.
  int score = 0;
  double _scoreUiTimer = 0;
  static const double _scoreUiInterval = 0.1;

  void _publishScore() {
    final v = score;
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

  /// Called on a crash when a respawn can be offered.
  VoidCallback? onCrash;

  static const int respawnBaseCost = 10; // gems for the first respawn in a run
  int _respawnsThisRun = 0;

  /// Doubles with every respawn in the same run: 10, 20, 40, ...
  int get respawnCost => respawnBaseCost * (1 << _respawnsThisRun);
  static const double respawnInvincibility = 2.0; // seconds

  Vector2? _panStart;
  static const double _swipeThreshold = 20.0;
  bool _panHandled = false;

  double _shakeTime = 0;
  bool _cameraShaken = false;
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

    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
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
    _scoreUiTimer += dt;
    if (_scoreUiTimer >= _scoreUiInterval) {
      _scoreUiTimer = 0;
      _publishScore();
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
      camera.viewfinder.position.setValues(
        size.x / 2 + (even ? amp : -amp),
        size.y / 2 + (even ? amp * 0.4 : -amp * 0.4),
      );
      _cameraShaken = true;
    } else if (_cameraShaken) {
      // Re-center once after a shake instead of every frame
      camera.viewfinder.position.setValues(size.x / 2, size.y / 2);
      _cameraShaken = false;
    }

    // Only update audio pitch when a new speed milestone is reached
    if (speedStep != _lastSpeedStep) {
      _lastSpeedStep = speedStep;
      AudioService().updateBgmPitch(worldSpeed);
    }

    // Move the lane reservations down with the world (clamped to prevent drift)
    final step = worldSpeed * frameScale(dt);
    _laneOccupiedUntil
        .updateAll((k, v) => (v + step).clamp(-10000.0, size.y + 500));
  }

  /// Converts a frame's dt into "60fps frames" so movement tuned per-frame
  /// stays the same speed at any refresh rate and doesn't jerk on a dropped
  /// frame. Capped so a long hitch can't teleport things through the player.
  static double frameScale(double dt) => (dt * 60).clamp(0.0, 3.0);

  // ── Input ────────────────────────────────────────────────────────────────
  @override
  void onPanStart(DragStartInfo info) {
    _panStart = info.eventPosition.global;
    _panHandled = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameState != RunnerGameState.playing) return;
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

  /// Called when the player hits an obstacle. Freezes the run and offers a
  /// respawn if the player can afford it; otherwise ends the run.
  void triggerGameOver() {
    if (gameState != RunnerGameState.playing) return;
    gameState = RunnerGameState.crashed;
    _publishScore(); // show the exact final score
    AudioService().stopBgm();
    AudioService().playSfx('crash.wav');

    if (onCrash != null && GameData().gems >= respawnCost) {
      onCrash!.call();
    } else {
      finalizeGameOver();
    }
  }

  /// Ends the run for good: saves high score and run coins, shows Game Over.
  void finalizeGameOver() {
    if (gameState == RunnerGameState.gameOver) return;
    gameState = RunnerGameState.gameOver;
    GameData().updateHighScore(score);
    // Add collected coins to global total only at the end of the run
    GameData().coins += coinsCollected;
    GameData().save();
    onGameOver?.call();
  }

  /// Continues the same run (score and coins kept) for [respawnCost] gems.
  bool respawn() {
    if (gameState != RunnerGameState.crashed) return false;
    if (GameData().gems < respawnCost) return false;
    GameData().gems -= respawnCost;
    _respawnsThisRun++;
    GameData().save();

    // Clear the road so the player doesn't crash again instantly
    obstacleSpawner.reset();
    _laneOccupiedUntil.updateAll((_, __) => 10000);
    _shakeTime = 0;
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);

    player.grantInvincibility(respawnInvincibility);
    AudioService().playBgm();
    gameState = RunnerGameState.playing;
    return true;
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
    score = 0;
    _scoreUiTimer = 0;
    scoreNotifier.value = 0;
    coinsNotifier.value = 0;
    worldSpeed = 6.0;
    _shakeTime = 0;
    _elapsedSecs = 0;
    _lastSpeedStep = 0;
    _scoreAccumulator = 0;
    _respawnsThisRun = 0;
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
