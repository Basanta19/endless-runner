import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/runner_game.dart';

/// Flame HUD — rendered last, not affected by camera.
/// Draws the speed bar and power-up timers directly on canvas.
// ignore: deprecated_member_use
class HudComponent extends Component with HasGameRef<RunnerGame> {
  @override
  int get priority => 100; // always on top

  // ── Cached Paint objects ────────────────────────────────────────────────
  static final Paint _barBgPaint = Paint()..color = Colors.white12;
  final Paint _barFillPaint = Paint();
  static final Paint _puBarBgPaint = Paint()..color = Colors.white12;
  final Paint _puBarFillPaint = Paint();

  // ── Cached TextPainters ─────────────────────────────────────────────────
  // Power-up label painters (cached once, text never changes)
  final TextPainter _magLabel = TextPainter(
    text: const TextSpan(
      text: 'MAG',
      style: TextStyle(
          color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final TextPainter _shiLabel = TextPainter(
    text: const TextSpan(
      text: 'SHI',
      style: TextStyle(
          color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final TextPainter _spdLabel = TextPainter(
    text: const TextSpan(
      text: 'SPD',
      style: TextStyle(
          color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void render(Canvas canvas) {
    final game = gameRef;
    final w = game.size.x;

    // Score is shown by the Flutter badge in GameScreen; drawing it here too
    // meant a text re-layout every frame for a duplicate hidden under it.

    // Speed bar (bottom)
    final speedFrac = ((game.worldSpeed - 6) / 12).clamp(0.0, 1.0);
    _barFillPaint.color = speedFrac < 0.4
        ? const Color(0xFF4CAF50)
        : speedFrac < 0.75
            ? const Color(0xFFFF8C00)
            : const Color(0xFFE53935);

    final barW = w - 48;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(24, game.size.y - 18, barW, 6),
          const Radius.circular(3)),
      _barBgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(24, game.size.y - 18, barW * speedFrac, 6),
          const Radius.circular(3)),
      _barFillPaint,
    );

    // Power-up Indicators
    _drawPowerUpTimers(canvas, game);
  }

  void _drawPowerUpTimers(Canvas canvas, RunnerGame game) {
    double y = 100;
    final player = game.player;

    if (player.magnetTimer > 0) {
      _drawBar(canvas, y, _magLabel, player.magnetTimer, player.magnetMax,
          Colors.blueAccent);
      y += 32;
    }
    if (player.shieldTimer > 0) {
      _drawBar(canvas, y, _shiLabel, player.shieldTimer, player.shieldMax,
          Colors.greenAccent);
      y += 32;
    }
    if (player.speedTimer > 0) {
      _drawBar(canvas, y, _spdLabel, player.speedTimer, player.speedMax,
          Colors.amberAccent);
    }
  }

  void _drawBar(Canvas canvas, double y, TextPainter label, double val,
      double max, Color color) {
    final pct = (val / max).clamp(0.0, 1.0);

    // Label (pre-laid-out)
    label.paint(canvas, Offset(24, y));

    // Bar background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(64, y + 4, 100, 6), const Radius.circular(3)),
      _puBarBgPaint,
    );
    // Bar fill
    _puBarFillPaint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(64, y + 4, 100 * pct, 6), const Radius.circular(3)),
      _puBarFillPaint,
    );
  }
}
