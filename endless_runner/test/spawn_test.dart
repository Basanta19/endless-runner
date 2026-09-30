import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runner_rush/features/obstacles/coin_component.dart';
import 'package:runner_rush/features/obstacles/obstacle_component.dart';
import 'package:runner_rush/runner_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the real game loop (spawners, pooling, collisions) without a device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    // No audio plugin on a PC test run: answer its calls with "ok". Audio
    // assets and the database are unavailable here too; the game handles
    // both gracefully (logs and carries on), which this test also covers.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
          MethodChannel(channel), (_) async => 1);
    }
  });

  /// Advances the game [frames] times by [dt], yielding like a real app so
  /// new components can finish loading. Returns the most coins / obstacles
  /// seen on screen at once.
  Future<(int, int)> play(RunnerGame game, int frames, double dt) async {
    int maxCoins = 0, maxObstacles = 0;
    for (int i = 0; i < frames; i++) {
      game.update(dt);
      await game.ready();
      final coins = game.children.whereType<CoinComponent>().length;
      final obstacles = game.children.whereType<ObstacleComponent>().length;
      if (coins > maxCoins) maxCoins = coins;
      if (obstacles > maxObstacles) maxObstacles = obstacles;
    }
    return (maxCoins, maxObstacles);
  }

  testWithGame<RunnerGame>(
    'coins and obstacles spawn and get recycled during a run',
    RunnerGame.new,
    (game) async {
      game.onGameResize(Vector2(400, 800));
      game.onCrash = () => game.respawn(); // keep running through crashes
      final (coins, obstacles) = await play(game, 1200, 1 / 60); // ~20s
      expect(coins, greaterThan(0));
      expect(obstacles, greaterThan(0));
    },
  );

  testWithGame<RunnerGame>(
    'a long lag spike slows everything down together',
    RunnerGame.new,
    (game) async {
      game.onGameResize(Vector2(400, 800));
      // One 2-second freeze: it's capped to a single 0.05s step, so score
      // (60/sec) advances by ~3 points — not 120 while objects stand still.
      final before = game.score;
      game.update(2.0);
      expect(game.score - before, lessThanOrEqualTo(3));
    },
  );

  /// Puts a coin right on top of the player, then runs [frames] frames
  /// (spawners paused so only this coin is in play). Returns coins collected.
  Future<int> coinUnderPlayer(RunnerGame game,
      {required bool jump, int frames = 60}) async {
    game.onGameResize(Vector2(400, 800));
    for (final s in [game.obstacleSpawner, game.coinSpawner]) {
      s.removeFromParent();
    }
    await game.ready();
    final p = game.player;
    final coin = CoinComponent()..reset(p.x + p.width / 2 - 17, p.y + 40);
    if (jump) p.jump();
    await game.ensureAdd(coin);
    for (int i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
    return game.coinsCollected;
  }

  testWithGame<RunnerGame>(
    'standing on a coin collects it',
    RunnerGame.new,
    (game) async {
      expect(await coinUnderPlayer(game, jump: false, frames: 5), 1);
    },
  );

  testWithGame<RunnerGame>(
    'jumping over a coin does not collect it',
    RunnerGame.new,
    (game) async {
      expect(await coinUnderPlayer(game, jump: true), 0);
    },
  );
}
