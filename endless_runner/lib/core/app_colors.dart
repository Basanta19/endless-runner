import 'package:flutter/material.dart';

class AppColors {
  // Primary blues (background, dark panels)
  static const Color darkBg = Color(0xFF0D1B2E);
  static const Color navyBlue = Color(0xFF1B3A6B);
  static const Color mediumBlue = Color(0xFF1B4F8A);
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color skyBlue = Color(0xFF29B6F6);

  // UI accent colors
  static const Color gold = Color(0xFFFFCC02);
  static const Color goldDark = Color(0xFFE6B800);
  static const Color orange = Color(0xFFFF8C00);
  static const Color orangeLight = Color(0xFFFFAB00);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenDark = Color(0xFF388E3C);
  static const Color red = Color(0xFFE53935);
  static const Color redDark = Color(0xFFC62828);
  static const Color yellow = Color(0xFFFFEB3B);

  // Panel colors
  static const Color panelDark = Color(0xFF152338);
  static const Color panelMid = Color(0xFF1E3A5F);
  static const Color panelLight = Color(0xFF2A4E7C);
  static const Color cardBorder = Color(0xFF3D6B9E);

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFB0C4DE);
  static const Color textGold = Color(0xFFFFCC02);
  static const Color textGray = Color(0xFF8A9BB0);

  // Road colors
  static const Color roadGray = Color(0xFF3D3D3D);
  static const Color roadLine = Color(0xFFFFFFFF);
  static const Color roadSide = Color(0xFF5A8A3C);

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

  static Color? get blue => null;
}
