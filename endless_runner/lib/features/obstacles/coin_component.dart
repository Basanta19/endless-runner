import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/features/player/player_component.dart';
import 'package:runner_rush/runner_game.dart';
import '../../services/audio_service.dart';

class CoinComponent extends PositionComponent
    with
        // ignore: deprecated_member_use
        HasGameRef<RunnerGame>,
        CollisionCallbacks {
  double _animOffset = 0;
  bool _collected = false;

  // Cached Paint Objects
  static final Paint _borderPaint = Paint()
    ..color = const Color(0xFFE65100)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _innerPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _glowPaint = Paint()
    ..color = Colors.yellow.withValues(alpha: 0.2);
  // Removed MaskFilter as it is extremely expensive on mobile

  // Face gradient built once for the full-size coin and shared by all coins.
  // The spin is done by squashing the canvas, so the shader never changes.
  static final Paint _facePaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(0, 0, 35, 35));

  CoinComponent({required Vector2 position}) : super(position: position) {
    size = Vector2(35, 35);
  }

  @override
  Future<void> onLoad() async {
    _animOffset = math.Random().nextDouble() * 10;
    await add(CircleHitbox(radius: 16));
  }

  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;
    final f = RunnerGame.frameScale(dt);
    // Move vertically downwards
    position.y += gameRef.worldSpeed * f;
    _animOffset += 0.12 * f;
    // Remove when off the bottom of the screen
    if (position.y > gameRef.size.y + 50) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_collected) return;
    if (other is PlayerComponent) {
      _collected = true;
      AudioService().playSfx('collect.wav', volume: 0.5);
      gameRef.collectCoin();
      // Spawn particle burst then remove
      gameRef.add(_CoinParticle(position: position.clone()));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);

    // Rotation effect (3D coin spinning)
    final spin = math.cos(_animOffset * 2);
    final coinWidth = (w * spin.abs()).clamp(1.0, w);

    // Glow (Simplified for performance)
    canvas.drawCircle(center, w / 2 + 2, _glowPaint);

    // Coin face — full-size oval squashed horizontally for the spin
    canvas.save();
    canvas.translate(center.dx, 0);
    canvas.scale(coinWidth / w, 1);
    canvas.translate(-center.dx, 0);
    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), _facePaint);
    canvas.restore();

    final rect = Rect.fromCenter(center: center, width: coinWidth, height: h);

    // Border
    canvas.drawOval(rect, _borderPaint);

    // Inner detail
    if (spin.abs() > 0.4) {
      canvas.drawOval(
        Rect.fromCenter(
            center: center, width: coinWidth * 0.6, height: h * 0.6),
        _innerPaint,
      );
    }
  }
}

/// Coin collect burst particle — auto-removes when done.
// ignore: deprecated_member_use
class _CoinParticle extends PositionComponent with HasGameRef<RunnerGame> {
  double _life = 1.0;
  double _vy = -3.0;

  _CoinParticle({required Vector2 position})
      : super(position: position, size: Vector2.zero());

  @override
  void update(double dt) {
    final f = RunnerGame.frameScale(dt);
    _vy += 0.2 * f;
    position.y += _vy * f;
    _life -= 0.06 * f;
    if (_life <= 0) removeFromParent();
  }

  // Cached Paints
  static final Paint _p1 = Paint()..color = const Color(0xFFFFCC00);
  static final Paint _p2 = Paint()
    ..color = const Color(0xFFFFE066)
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final op = _life.clamp(0.0, 1.0);
    _p1.color = const Color(0xFFFFCC00).withValues(alpha: op);
    canvas.drawCircle(Offset.zero, 8 * op, _p1);

    _p2.color = const Color(0xFFFFE066).withValues(alpha: op);
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + (1 - op) * math.pi;
      final len = 12 * op;
      canvas.drawLine(Offset.zero,
          Offset(math.cos(angle) * len, math.sin(angle) * len), _p2);
    }
  }
}
