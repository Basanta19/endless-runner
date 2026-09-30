import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/core/game_data.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/core/missions.dart';
import 'package:runner_rush/features/player/player_component.dart';
import 'package:runner_rush/runner_game.dart';

enum ObstacleType { barrier, container, bus, cone, hurdle }

class ObstacleComponent extends PositionComponent
    with
        // ignore: deprecated_member_use
        HasGameRef<RunnerGame>,
        CollisionCallbacks {
  final ObstacleType type;
  bool _hitPlayer = false;

  // Cached Paint Objects for Performance
  static final Paint _greyPaint = Paint()..color = Colors.grey;
  static final Paint _barrierBoardPaint = Paint()
    ..color = const Color(0xFFE65100);
  static final Paint _stripePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12;
  static final Paint _lightPaint = Paint();
  static final Paint _containerBodyPaint = Paint()
    ..color = const Color(0xFFCC2200);
  static final Paint _corrugatedPaint = Paint()
    ..color = Colors.black26
    ..strokeWidth = 3;
  static final Paint _busBodyPaint = Paint()..color = const Color(0xFF0D47A1);
  static final Paint _windowPaint = Paint()..color = const Color(0xFF81D4FA);
  static final Paint _blackPaint = Paint()..color = Colors.black;
  static final Paint _conePaint = Paint()..color = const Color(0xFFFF6F00);
  static final Paint _coneStripePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.7);
  static final Paint _coneBasePaint = Paint()..color = const Color(0xFFE65100);
  static final Paint _polePaint = Paint()..color = const Color(0xFFE53935);
  static final Paint _barPaint = Paint()..color = const Color(0xFFFFCC00);

  final Path _conePath = Path();
  final Path _stripePath = Path();

  ObstacleComponent(
      {required Vector2 position, required Vector2 size, required this.type})
      : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    // Slightly inset hitbox for fairness
    await add(RectangleHitbox(
      size: Vector2(size.x - 14, size.y - 10),
      position: Vector2(7, 5),
    ));
  }

  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;
    // Move vertically downwards
    position.y += gameRef.worldSpeed * RunnerGame.frameScale(dt);
    // Remove when off the bottom of the screen — it passed the player
    if (position.y > gameRef.size.y + 100) {
      if (!_hitPlayer) GameData().addMissionProgress(MissionType.dodge);
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      // Ignore all collisions if player is currently invincible (mercy period)
      if (other.isInvincible) return;

      // Check if player is jumping over a "low" obstacle
      final canJumpOver = type == ObstacleType.cone ||
          type == ObstacleType.barrier ||
          type == ObstacleType.hurdle;

      if (canJumpOver && other.jumpHeight > 20) {
        return; // Successfully jumped over
      }

      // Check if player is sliding under a hurdle
      if (type == ObstacleType.hurdle && other.isSliding) {
        return; // Successfully slid under
      }

      final isLarge =
          type == ObstacleType.bus || type == ObstacleType.container;

      // Check for Shield logic
      if (other.shieldTimer > 0) {
        if (isLarge) {
          // Large objects (Bus/Container) ignore shield!
          gameRef.triggerShake();
          gameRef.triggerGameOver();
          return;
        } else {
          // Small objects use up the shield
          _hitPlayer = true; // Absorbed by shield, not a dodge
          other.hitShield(); // This resets the shield timer
          gameRef.triggerShake();
          return;
        }
      }

      gameRef.triggerShake();
      gameRef.triggerGameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    // Lazy-init paths if needed
    if (_conePath.getBounds().isEmpty) {
      final w = size.x;
      final h = size.y;
      _conePath.moveTo(w / 2, 0);
      _conePath.lineTo(w, h);
      _conePath.lineTo(0, h);
      _conePath.close();

      _stripePath.moveTo(w * 0.25, h * 0.5);
      _stripePath.lineTo(w * 0.75, h * 0.5);
      _stripePath.lineTo(w * 0.7, h * 0.65);
      _stripePath.lineTo(w * 0.3, h * 0.65);
      _stripePath.close();
    }

    switch (type) {
      case ObstacleType.barrier:
        _drawBarrier(canvas);
        break;
      case ObstacleType.container:
        _drawContainer(canvas);
        break;
      case ObstacleType.bus:
        _drawBus(canvas);
        break;
      case ObstacleType.cone:
        _drawCone(canvas);
        break;
      case ObstacleType.hurdle:
        _drawHurdle(canvas);
        break;
    }
  }

  void _drawBarrier(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Legs
    canvas.drawRect(
        Rect.fromLTWH(w * 0.1, h * 0.5, w * 0.1, h * 0.5), _greyPaint);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.8, h * 0.5, w * 0.1, h * 0.5), _greyPaint);

    // Main board
    final boardRect = Rect.fromLTWH(0, h * 0.1, w, h * 0.4);
    canvas.drawRect(boardRect, _barrierBoardPaint);

    // Realistic Stripes (reduced density for performance)
    for (double i = -20; i < w; i += 50) {
      canvas.drawLine(
          Offset(i, h * 0.1), Offset(i + 35, h * 0.5), _stripePaint);
    }

    // Blinking lights
    final blink = (math.sin(gameRef.elapsedSecs * 10) > 0);
    _lightPaint.color = blink ? Colors.yellow : const Color(0xFF8B4513);
    canvas.drawCircle(Offset(w * 0.15, h * 0.1), 5, _lightPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.1), 5, _lightPaint);
  }

  void _drawContainer(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h), const Radius.circular(6)),
        _containerBodyPaint);

    // Corrugated texture (vertical lines - reduced)
    for (int i = 1; i < 4; i++) {
      final lx = (w / 4) * i;
      canvas.drawLine(Offset(lx, 5), Offset(lx, h - 5), _corrugatedPaint);
    }

    // Corner reinforcements
    canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 8), _greyPaint);
    canvas.drawRect(Rect.fromLTWH(w - 8, 0, 8, 8), _greyPaint);
    canvas.drawRect(Rect.fromLTWH(0, h - 8, 8, 8), _greyPaint);
    canvas.drawRect(Rect.fromLTWH(w - 8, h - 8, 8, 8), _greyPaint);
  }

  void _drawBus(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Main Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, h * 0.1, w, h * 0.9), const Radius.circular(10)),
        _busBodyPaint);

    // Front Windshield
    canvas.drawRect(
        Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.25), _windowPaint);

    // Destination board (Simple black box)
    canvas.drawRect(
        Rect.fromLTWH(w * 0.2, h * 0.12, w * 0.6, h * 0.06), _blackPaint);

    // Grille
    canvas.drawRect(
        Rect.fromLTWH(w * 0.3, h * 0.7, w * 0.4, h * 0.12), _greyPaint);

    // Headlights (Solid for performance)
    canvas.drawCircle(Offset(w * 0.2, h * 0.76), 6, _eyeWhitePaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.76), 6, _eyeWhitePaint);
  }

  static final Paint _eyeWhitePaint = Paint()..color = Colors.white;

  void _drawCone(Canvas canvas) {
    final h = size.y;
    final w = size.x;
    canvas.drawPath(_conePath, _conePaint);
    canvas.drawPath(_stripePath, _coneStripePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-4, h - 6, w + 8, 6), const Radius.circular(3)),
        _coneBasePaint);
  }

  void _drawHurdle(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(4, 0, 8, h), const Radius.circular(4)),
        _polePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w - 12, 0, 8, h), const Radius.circular(4)),
        _polePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, h * 0.25, w, 10), const Radius.circular(5)),
        _barPaint);
  }
}
