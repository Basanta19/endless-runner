import 'package:flutter/material.dart';

class AppColors {
  // Primary blues (background, dark panels)
  static const Color mediumBlue = Color(0xFF1B4F8A);
  static const Color lightBlue = Color(0xFF2196F3);

  // UI accent colors
  static const Color gold = Color(0xFFFFCC02);
  static const Color orange = Color(0xFFFF8C00);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFE53935);

  // Panel colors
  static const Color panelDark = Color(0xFF152338);
  static const Color panelMid = Color(0xFF1E3A5F);
  static const Color panelLight = Color(0xFF2A4E7C);
  static const Color cardBorder = Color(0xFF3D6B9E);

  // Text
  static const Color textLight = Color(0xFFB0C4DE);
  static const Color textGold = Color(0xFFFFCC02);
  static const Color textGray = Color(0xFF8A9BB0);

  // Button gradients
  static const LinearGradient playBtn = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFF6F00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient greenBtn = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient blueBtn = LinearGradient(
    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient redBtn = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient yellowBtn = LinearGradient(
    colors: [Color(0xFFFFEE58), Color(0xFFF9A825)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Background gradient
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0D1B2E), Color(0xFF1B3A6B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
