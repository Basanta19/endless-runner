import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/core/game_data.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/core/missions.dart';
import 'package:runner_rush/runner_game.dart';
import '../../services/audio_service.dart';
import '../player/player_component.dart';

enum PowerUpType { magnet, shield, speed }

class PowerUpComponent extends PositionComponent
    with
        // ignore: deprecated_member_use
        HasGameRef<RunnerGame>,
        CollisionCallbacks {
  final PowerUpType type;
  double _animTime = 0;
  bool _collected = false;

  // ── Cached Paint objects (avoid per-frame allocation) ───────────────────
  late final Color _glowColor;
  late final Paint _glowPaint;
  late final Paint _ringPaint;
  static final Paint _capsulePaint = Paint()..color = const Color(0xFF263238);
  static final Paint _capsuleStrokePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _magnetPaint = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round;
  static final Paint _tipPaint = Paint()..color = Colors.white;
  static final Paint _shieldFillPaint = Paint()..color = Colors.greenAccent;
  static final Paint _shieldStrokePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _speedPaint = Paint()..color = Colors.amberAccent;

  PowerUpComponent({required Vector2 position, required this.type})
      : super(position: position, size: Vector2(55, 55)) {
    _glowColor = type == PowerUpType.magnet
        ? Colors.blueAccent
        : type == PowerUpType.shield
            ? Colors.greenAccent
            : Colors.amberAccent;
    _glowPaint = Paint()..color = _glowColor.withValues(alpha: 0.15);
    _ringPaint = Paint()
      ..color = _glowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
  }

  @override
  Future<void> onLoad() async {
    await add(CircleHitbox(radius: 24));
  }

  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;

    // Move vertically downwards
    position.y += gameRef.worldSpeed;
    _animTime += dt;

    // Remove when off screen
    if (position.y > gameRef.size.y + 100) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      if (_collected) return;
      _collected = true;
      GameData().addMissionProgress(MissionType.powerUp);
      AudioService().playSfx('powerup.wav');
      if (type == PowerUpType.magnet) {
        other.activateMagnet();
      } else if (type == PowerUpType.shield) {
        other.activateShield();
      } else if (type == PowerUpType.speed) {
        other.activateSpeed();
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final bounce = math.sin(_animTime * 4) * 6;
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2 + bounce);

    // Soft glow — two layered circles instead of expensive MaskFilter.blur
    canvas.drawCircle(center, 32, _glowPaint);
    canvas.drawCircle(center, 28, _glowPaint);

    // Rotating Ring
    final ringRadius = 22.0 + math.sin(_animTime * 6) * 2;
    canvas.drawCircle(center, ringRadius, _ringPaint);

    // Main capsule
    canvas.drawCircle(center, 18, _capsulePaint);
    canvas.drawCircle(center, 18, _capsuleStrokePaint);

    // Icon
    if (type == PowerUpType.magnet) {
      _drawMagnetIcon(canvas, center);
    } else if (type == PowerUpType.shield) {
      _drawShieldIcon(canvas, center);
    } else {
      _drawSpeedIcon(canvas, center);
    }
  }

  void _drawMagnetIcon(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx - 8, center.dy + 8)
      ..lineTo(center.dx - 8, center.dy - 4)
      ..arcToPoint(Offset(center.dx + 8, center.dy - 4),
          radius: const Radius.circular(8))
      ..lineTo(center.dx + 8, center.dy + 8);

    canvas.drawPath(path, _magnetPaint);

    // White tips
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(center.dx - 8, center.dy + 6), width: 6, height: 4),
        _tipPaint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(center.dx + 8, center.dy + 6), width: 6, height: 4),
        _tipPaint);
  }

  void _drawShieldIcon(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 10)
      ..lineTo(center.dx + 8, center.dy - 6)
      ..lineTo(center.dx + 8, center.dy + 4)
      ..quadraticBezierTo(
          center.dx, center.dy + 10, center.dx - 8, center.dy + 4)
      ..lineTo(center.dx - 8, center.dy - 6)
      ..close();

    canvas.drawPath(path, _shieldFillPaint);
    canvas.drawPath(path, _shieldStrokePaint);
  }

  void _drawSpeedIcon(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx + 4, center.dy - 12)
      ..lineTo(center.dx - 8, center.dy + 2)
      ..lineTo(center.dx - 2, center.dy + 2)
      ..lineTo(center.dx - 4, center.dy + 12)
      ..lineTo(center.dx + 8, center.dy - 2)
      ..lineTo(center.dx + 2, center.dy - 2)
      ..close();

    canvas.drawPath(path, _speedPaint);
  }
}
