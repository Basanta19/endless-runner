import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final Gradient gradient;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback onTap;

  const GradientButton({
    super.key,
    required this.label,
    required this.gradient,
    this.fontSize = 20,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    required this.onTap,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 0,
                  offset: const Offset(0, -2),
                  spreadRadius: -1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onLeaderboard;
  final VoidCallback onSettings;

  const BottomNavBar({
    super.key,
    required this.onHome,
    required this.onLeaderboard,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.panelDark.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.leaderboard_rounded, 'RANKS', onLeaderboard),
          _navItem(Icons.home_rounded, 'HOME', onHome, isActive: true),
          _navItem(Icons.settings_rounded, 'SETTINGS', onSettings),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.gold : AppColors.textGray,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.gold : AppColors.textGray,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.panelMid,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          if (showBackButton) const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  const AppSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class AppCoinBadge extends StatelessWidget {
  final String value;
  final Color color;

  const AppCoinBadge({
    super.key,
    required this.value,
    this.color = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class AppActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget? trailing;
  final Widget? bottom;
  final VoidCallback? onTap;

  const AppActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.leading,
    this.trailing,
    this.bottom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panelMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(width: 28, height: 28, child: Center(child: leading)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (bottom != null) ...[
                    const SizedBox(height: 8),
                    bottom!,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class MagnetIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MagnetIcon({super.key, this.size = 24, this.color = Colors.redAccent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MagnetPainter(color),
    );
  }
}

class _MagnetPainter extends CustomPainter {
  final Color color;
  _MagnetPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.25
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.4)
      ..arcToPoint(
        Offset(size.width * 0.8, size.height * 0.4),
        radius: Radius.circular(size.width * 0.3),
      )
      ..lineTo(size.width * 0.8, size.height * 0.8);

    canvas.drawPath(path, paint);

    // Silver/White tips
    final tipPaint = Paint()..color = Colors.white70;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.2, size.height * 0.75),
        width: size.width * 0.26,
        height: size.height * 0.15,
      ),
      tipPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.75),
        width: size.width * 0.26,
        height: size.height * 0.15,
      ),
      tipPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
