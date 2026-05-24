import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:runner_rush/runner_game.dart';

// ignore: deprecated_member_use
class RoadComponent extends Component with HasGameRef<RunnerGame> {
  double _scrollOffset = 0;

  // Cached Paint Objects
  final Paint _roadPaint = Paint()..color = const Color(0xFF3D3D3D);
  final Paint _borderPaint = Paint()
    ..color = Colors.white24
    ..strokeWidth = 2;
  final Paint _dashPaint = Paint()
    ..color = Colors.white38
    ..strokeWidth = 3;

  @override
  void update(double dt) {
    if (gameRef.gameState.index == 1) {
      // playing
      _scrollOffset += gameRef.worldSpeed * 1.5;
    }
  }

  @override
  void render(Canvas canvas) {
    final w = gameRef.size.x;
    final h = gameRef.size.y;

    // 1. Full-Width Road (matching Home Page)
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _roadPaint);

    // 2. Top Border line
    canvas.drawLine(const Offset(0, 0), Offset(w, 0), _borderPaint);

    // 3. Lane Markings
    _drawLaneMarkers(canvas, w, h);
  }

  void _drawLaneMarkers(Canvas canvas, double w, double h) {
    const dashStep = 120.0;
    const dashLen = 60.0;
    final offset = _scrollOffset % dashStep;

    // Two dashed lines dividing the 3 lanes
    for (final lx in [w * 0.36, w * 0.64]) {
      for (double y = -dashStep + offset; y < h; y += dashStep) {
        canvas.drawLine(Offset(lx, y), Offset(lx, y + dashLen), _dashPaint);
      }
    }

    // (Road Glow removed for performance as requested)
  }
}
