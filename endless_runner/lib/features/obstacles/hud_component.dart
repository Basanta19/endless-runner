import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/runner_game.dart';

/// Flame HUD — rendered last, not affected by camera.
/// Draws score, speed bar, coin counter directly on canvas.
// ignore: deprecated_member_use
class HudComponent extends Component with HasGameRef<RunnerGame> {
  @override
  int get priority => 100; // always on top

  @override
  void render(Canvas canvas) {
    final game = gameRef;
    final w = game.size.x;

    // Score
    final scorePainter = TextPainter(
      text: TextSpan(
        text: '${game.score}',
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scorePainter.paint(canvas, const Offset(70, 16));

    // (Coins collected this run removed as requested - total coins shown in main UI)

    // Speed bar (bottom)
    final speedFrac = ((game.worldSpeed - 6) / 12).clamp(0.0, 1.0);
    final barColor = speedFrac < 0.4
        ? const Color(0xFF4CAF50)
        : speedFrac < 0.75
            ? const Color(0xFFFF8C00)
            : const Color(0xFFE53935);

    final barW = w - 48;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(24, game.size.y - 18, barW, 6),
          const Radius.circular(3)),
      Paint()..color = Colors.white12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(24, game.size.y - 18, barW * speedFrac, 6),
          const Radius.circular(3)),
      Paint()..color = barColor,
    );

    // Power-up Indicators
    _drawPowerUpTimers(canvas, game);
  }

  void _drawPowerUpTimers(Canvas canvas, RunnerGame game) {
    double y = 100;
    final player = game.player;

    if (player.magnetTimer > 0) {
      _drawBar(canvas, y, "MAG", player.magnetTimer, player.magnetMax,
          Colors.blueAccent);
      y += 32;
    }
    if (player.shieldTimer > 0) {
      _drawBar(canvas, y, "SHI", player.shieldTimer, player.shieldMax,
          Colors.greenAccent);
      y += 32;
    }
    if (player.speedTimer > 0) {
      _drawBar(canvas, y, "SPD", player.speedTimer, player.speedMax,
          Colors.amberAccent);
    }
  }

  void _drawBar(Canvas canvas, double y, String label, double val, double max,
      Color color) {
    final pct = (val / max).clamp(0.0, 1.0);

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(24, y));

    // Bar background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(64, y + 4, 100, 6), const Radius.circular(3)),
      Paint()..color = Colors.white12,
    );
    // Bar fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(64, y + 4, 100 * pct, 6), const Radius.circular(3)),
      Paint()..color = color,
    );
  }
}
