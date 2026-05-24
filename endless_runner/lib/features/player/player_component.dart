import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/core/game_data.dart';
import 'package:runner_rush/core/game_state.dart';
import 'package:runner_rush/runner_game.dart';
import '../../services/audio_service.dart';

enum _Lane { left, center, right }

class PlayerComponent extends PositionComponent
    with
        // ignore: deprecated_member_use
        HasGameRef<RunnerGame>,
        CollisionCallbacks {
  static const double pw = 85;
  static const double ph = 130;
  static const double gravity = 1.1;
  static const double jumpPower = -24.0;
  static const double snapFactor = 0.30;

  _Lane _lane = _Lane.center;
  double _targetX = 0;
  double _velY = 0;
  bool _onGround = true;
  bool _sliding = false;
  int _slideFrames = 0;
  bool _canDoubleJump = true;
  double runFrame = 0;
  double _jumpHeight = 0;
  double _magnetTimer = 0;
  double _shieldTimer = 0;
  double _speedTimer = 0;
  double _magnetMax = 1;
  double _shieldMax = 1;
  double _speedMax = 1;
  double _shieldBreakTime = 0;
  double _invincibleTimer = 0;

  // Cached Paint Objects for Performance
  final Paint _bodyPaint = Paint();
  final Paint _skinPaint = Paint();
  final Paint _hairPaint = Paint()..color = const Color(0xFF4A2800);
  final Paint _pantsPaint = Paint()..color = const Color(0xFF1565C0);
  final Paint _shoesPaint = Paint()..color = const Color(0xFF212121);
  final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.22);
  final Paint _backpackPaint = Paint()..color = const Color(0xFF37474F);
  final Paint _eyeWhitePaint = Paint()..color = Colors.white;
  final Paint _eyeBlackPaint = Paint()..color = Colors.black;
  final Paint _shieldPaint = Paint()
    ..color = Colors.greenAccent.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _magnetPaint = Paint()
    ..color = Colors.blueAccent.withValues(alpha: 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  bool get isJumping => !_onGround && _jumpHeight > 10;
  bool get isSliding => _sliding;
  double get jumpHeight => _jumpHeight;
  double get speedMultiplier => _speedTimer > 0 ? 1.6 : 1.0;
  bool get isInvincible => _invincibleTimer > 0;

  double get magnetTimer => _magnetTimer;
  double get shieldTimer => _shieldTimer;
  double get speedTimer => _speedTimer;
  double get magnetMax => _magnetMax;
  double get shieldMax => _shieldMax;
  double get speedMax => _speedMax;

  @override
  Future<void> onLoad() async {
    size = Vector2(pw, ph);
    final h = RectangleHitbox(
      size: Vector2(pw - 30, ph - 26),
      position: Vector2(15, 13),
    );
    await add(h);
    _updateTargetX();
    position.x = _targetX;
    position.y = gameRef.groundY - ph;
  }

  void _updateTargetX() {
    switch (_lane) {
      case _Lane.left:
        _targetX = gameRef.laneLeft - pw / 2;
        break;
      case _Lane.center:
        _targetX = gameRef.laneCenter - pw / 2;
        break;
      case _Lane.right:
        _targetX = gameRef.laneRight - pw / 2;
        break;
    }
  }

  // ── Movement commands ────────────────────────────────────────────────────
  void moveLeft() {
    if (_lane == _Lane.center) {
      _lane = _Lane.left;
    } else if (_lane == _Lane.right) {
      _lane = _Lane.center;
    }
    _updateTargetX();
  }

  void moveRight() {
    if (_lane == _Lane.center) {
      _lane = _Lane.right;
    } else if (_lane == _Lane.left) {
      _lane = _Lane.center;
    }
    _updateTargetX();
  }

  void jump() {
    if (_sliding) {
      _sliding = false;
      _slideFrames = 0;
    }
    if (_onGround) {
      AudioService().playSfx('jump.wav');
      final jumpMult =
          GameData.characterJumpMultiplier[GameData().selectedCharacter];
      _velY = jumpPower * jumpMult;
      _jumpHeight = 1; // Small initial lift
      _onGround = false;
      _canDoubleJump = true;
    } else if (_canDoubleJump) {
      _velY = jumpPower * 0.85;
      _canDoubleJump = false;
    }
  }

  void slide() {
    if (!_onGround) {
      _velY = 25;
      return;
    }
    if (!_sliding) {
      _sliding = true;
      _slideFrames = 40;
    }
  }

  void activateMagnet() {
    // Level 1: 10s, Level 5: 18s
    final duration = 10.0 + (GameData().magnetLevel - 1) * 2.0;
    _magnetTimer = duration;
    _magnetMax = duration;
  }

  void activateShield() {
    // Level 1: 10s, Level 5: 18s
    final duration = 10.0 + (GameData().shieldLevel - 1) * 2.0;
    _shieldTimer = duration;
    _shieldMax = duration;
  }

  void activateSpeed() {
    // Level 1: 10s, Level 5: 18s
    final duration = 10.0 + (GameData().speedLevel - 1) * 2.0;
    _speedTimer = duration;
    _speedMax = duration;
  }

  bool hitShield() {
    if (_shieldTimer > 0) {
      _shieldTimer = 0; // Shield used up
      _shieldBreakTime = 0.6; // Trigger animation
      _invincibleTimer = 1.5; // Brief mercy period
      return true;
    }
    return false;
  }

  void reset() {
    _lane = _Lane.center;
    _updateTargetX();
    position.x = _targetX;
    position.y = gameRef.groundY - ph;
    _velY = 0;
    _onGround = true;
    _sliding = false;
    _slideFrames = 0;
    _canDoubleJump = true;
    _jumpHeight = 0;
    _magnetTimer = 0;
    _shieldTimer = 0;
    _speedTimer = 0;
    _shieldBreakTime = 0;
    _invincibleTimer = 0;
    runFrame = 0;
  }

  // ── Flame update ─────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    if (gameRef.gameState != RunnerGameState.playing) return;

    // Lane snap
    final diff = _targetX - position.x;
    position.x += diff.abs() < 1 ? diff : diff * snapFactor;

    // Gravity & Jumping
    if (!_onGround) {
      _velY += gravity;
      _jumpHeight -= _velY; // Up is positive for jump height
      if (_jumpHeight <= 0) {
        _jumpHeight = 0;
        _velY = 0;
        _onGround = true;
        _canDoubleJump = true;
      }
    }

    // Slide countdown
    if (_sliding) {
      _slideFrames--;
      if (_slideFrames <= 0) _sliding = false;
    }

    runFrame += _onGround ? 0.22 : 0.05;

    // Magnet attraction
    if (_magnetTimer > 0) {
      _magnetTimer -= dt;
      final coins = gameRef.children.whereType<PositionComponent>().where((c) {
        // Simple type check since we can't import CoinComponent easily here without circularity
        // Actually we can import it, but let's look for distance
        return c.toString().contains('CoinComponent');
      });

      for (final coin in coins) {
        final dist = (coin.position - position).length;
        if (dist < 250) {
          final dir = (position - coin.position).normalized();
          coin.position += dir * 10.0;
        }
      }
    }

    // Shield timer
    if (_shieldTimer > 0) {
      _shieldTimer -= dt;
    }

    // Speed timer
    if (_speedTimer > 0) {
      _speedTimer -= dt;
    }

    if (_shieldBreakTime > 0) {
      _shieldBreakTime -= dt;
    }

    if (_invincibleTimer > 0) {
      _invincibleTimer -= dt;
    }

    // Update hitbox for sliding
    final hb = children.whereType<RectangleHitbox>().first;
    if (_sliding) {
      // Scale hitbox down for sliding under hurdles
      hb.size = Vector2(pw - 30, ph * 0.40);
      hb.position = Vector2(15, ph * 0.55);
    } else {
      // Normal hitbox (matches onLoad)
      hb.size = Vector2(pw - 30, ph - 26);
      hb.position = Vector2(15, 13);
    }
  }

  // ── Render ───────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final bodyColor =
        GameData.characterBodyColors[GameData().selectedCharacter];
    final skinColor =
        GameData.characterSkinColors[GameData().selectedCharacter];
    final runCycle = math.sin(runFrame * 2.5);
    const cx = pw / 2;

    canvas.save();

    // Blinking effect when invincible
    bool isVisible = true;
    if (_invincibleTimer > 0) {
      isVisible = (math.sin(_invincibleTimer * 25) > 0);
    }

    if (isVisible) {
      // Offset for jump visual elevation
      canvas.translate(0, -_jumpHeight);

      if (_sliding) {
        _renderSliding(canvas, cx, bodyColor, skinColor);
      } else {
        _renderRunning(canvas, cx, runCycle, bodyColor, skinColor);
      }

      // Power-up visual effects
      if (_shieldTimer > 0) {
        canvas.drawCircle(const Offset(cx, ph / 2), 50, _shieldPaint);
      }
      if (_magnetTimer > 0) {
        final pulse = math.sin(runFrame * 10) * 5;
        canvas.drawCircle(const Offset(cx, ph / 2), 45 + pulse, _magnetPaint);
      }
      // Shield Break Animation (Expanding ring)
      if (_shieldBreakTime > 0) {
        final alpha = (_shieldBreakTime / 0.6 * 255).toInt();
        final radius = 50.0 + (0.6 - _shieldBreakTime) * 200;
        canvas.drawCircle(
          const Offset(cx, ph / 2),
          radius,
          Paint()
            ..color = Colors.greenAccent.withValues(alpha: alpha / 255)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }

    canvas.restore();
  }

  void _renderRunning(Canvas canvas, double cx, double runCycle,
      Color bodyColor, Color skinColor) {
    final legSwing = runCycle * 10;
    final armSwing = -runCycle * 8;

    _bodyPaint.color = bodyColor;
    _skinPaint.color = skinColor;

    // Ground shadow
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, ph - 4), width: 60, height: 14),
        _shadowPaint);

    // Backpack (behind player)
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 65), width: 38, height: 45),
            const Radius.circular(8)),
        _backpackPaint);

    // Legs
    _limb(canvas, cx - 14, 85, legSwing, 30, 14, _pantsPaint);
    _shoe(canvas, cx - 14 + math.sin(legSwing * math.pi / 180) * 18, 112,
        _shoesPaint);
    _limb(canvas, cx + 14, 85, -legSwing, 30, 14, _pantsPaint);
    _shoe(canvas, cx + 14 + math.sin(-legSwing * math.pi / 180) * 18, 112,
        _shoesPaint);

    // Torso (Solid for performance, or cached shader if needed)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 58), width: 54, height: 52),
          const Radius.circular(12)),
      _bodyPaint,
    );

    // Arms
    _limb(canvas, cx - 30, 48, armSwing, 28, 12, _bodyPaint);
    _limb(canvas, cx + 30, 48, -armSwing, 28, 12, _bodyPaint);

    // Neck
    canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, 30), width: 18, height: 14),
        _skinPaint);

    // Head
    final headRect =
        Rect.fromCenter(center: Offset(cx, 16), width: 46, height: 42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(14)),
      _skinPaint,
    );

    _drawDetailedHair(canvas, cx, _hairPaint);

    // Eyes
    canvas.drawCircle(Offset(cx - 10, 14), 5, _eyeWhitePaint);
    canvas.drawCircle(Offset(cx + 10, 14), 5, _eyeWhitePaint);
    canvas.drawCircle(Offset(cx - 8, 14), 2.5, _eyeBlackPaint);
    canvas.drawCircle(Offset(cx + 11, 14), 2.5, _eyeBlackPaint);
  }

  void _renderSliding(
      Canvas canvas, double cx, Color bodyColor, Color skinColor) {
    const sy = ph * 0.45;
    _bodyPaint.color = bodyColor;
    _skinPaint.color = skinColor;

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, sy + 45), width: 80, height: 18),
        _shadowPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, sy + 22), width: 85, height: 35),
            const Radius.circular(12)),
        _bodyPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + 25, sy + 38), width: 45, height: 22),
            const Radius.circular(8)),
        _pantsPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx - 32, sy + 12), width: 42, height: 35),
            const Radius.circular(10)),
        _skinPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 52, sy - 4, 42, 20), const Radius.circular(8)),
        _hairPaint);
  }

  void _drawDetailedHair(Canvas canvas, double cx, Paint hair) {
    // Main hair volume
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 24, -6, 48, 24), const Radius.circular(10)),
      hair,
    );

    // Multiple spikes for realism
    for (int i = 0; i < 3; i++) {
      final xOffset = (i - 1) * 15.0;
      final spike = Path()
        ..moveTo(cx + xOffset - 8, -4)
        ..lineTo(cx + xOffset, -20 - (i % 2 * 5))
        ..lineTo(cx + xOffset + 8, -4)
        ..close();
      canvas.drawPath(spike, hair);
    }
  }

  void _limb(Canvas canvas, double x, double y, double angle, double len,
      double thick, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, len / 2), width: thick, height: len),
          const Radius.circular(4)),
      paint,
    );
    canvas.restore();
  }

  void _shoe(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 14, height: 7),
          const Radius.circular(3)),
      paint,
    );
  }
}
