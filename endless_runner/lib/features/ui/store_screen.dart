import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import 'app_widgets.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final GameData _gd = GameData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'UPGRADES',
                trailing: AppCoinBadge(value: '${_gd.coins}'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const AppSectionHeader(title: 'POWER-UP UPGRADES'),
                    _upgradeTile(
                      'MAGNET',
                      'Attracts coins • +2s/lvl',
                      _gd.magnetLevel,
                      () => _upgrade('MAGNET'),
                      const MagnetIcon(size: 24),
                    ),
                    _upgradeTile(
                      'SHIELD',
                      'Protects player • +2s/lvl',
                      _gd.shieldLevel,
                      () => _upgrade('SHIELD'),
                      const Icon(Icons.shield_rounded,
                          color: AppColors.gold, size: 24),
                    ),
                    _upgradeTile(
                      'SPEED BOOST',
                      '+2s/lvl',
                      _gd.speedLevel,
                      () => _upgrade('SPEED'),
                      const Icon(Icons.bolt_rounded,
                          color: AppColors.gold, size: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upgradeTile(String title, String desc, int level, VoidCallback onTap,
      Widget leading) {
    bool isMax = level >= GameData.maxPowerUpLevel;
    int cost = _gd.getUpgradeCost(level);

    return AppActionTile(
      title: title,
      subtitle: '$desc • LEVEL $level',
      leading: leading,
      trailing: isMax
          ? const Text('MAX',
              style: TextStyle(
                  color: AppColors.green, fontWeight: FontWeight.w900))
          : GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.yellowBtn,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text('$cost',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
      bottom: _LevelDots(level: level),
      onTap: isMax ? null : onTap,
    );
  }

  void _upgrade(String type) {
    int cost = 0;
    if (type == 'MAGNET') cost = _gd.getUpgradeCost(_gd.magnetLevel);
    if (type == 'SHIELD') cost = _gd.getUpgradeCost(_gd.shieldLevel);
    if (type == 'SPEED') cost = _gd.getUpgradeCost(_gd.speedLevel);

    if (_gd.coins >= cost) {
      setState(() {
        _gd.coins -= cost;
        if (type == 'MAGNET') _gd.magnetLevel++;
        if (type == 'SHIELD') _gd.shieldLevel++;
        if (type == 'SPEED') _gd.speedLevel++;
        _gd.save();
      });
      // The level dots animate a "+1" themselves
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not enough coins!')));
    }
  }
}

/// Level dots that pop the new dot and float a "+1" when the level goes up.
class _LevelDots extends StatefulWidget {
  final int level;
  const _LevelDots({required this.level});

  @override
  State<_LevelDots> createState() => _LevelDotsState();
}

class _LevelDotsState extends State<_LevelDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didUpdateWidget(_LevelDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level > oldWidget.level) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final animating = _ctrl.isAnimating;
        final newDot = widget.level - 1;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: List.generate(GameData.maxPowerUpLevel, (i) {
                // Newest dot pops in size
                final pop =
                    animating && i == newDot ? math.sin(t * math.pi) * 0.8 : 0;
                return Transform.scale(
                  scale: 1 + pop.toDouble(),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color:
                          i < widget.level ? AppColors.green : Colors.white12,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
            if (animating)
              Positioned(
                // Starts above the newest dot and floats upward
                left: newDot * 12.0 - 4,
                top: -6 - 26 * Curves.easeOut.transform(t),
                child: Opacity(
                  opacity: t < 0.7 ? 1 : ((1 - t) / 0.3).clamp(0.0, 1.0),
                  child: const Text(
                    '+1',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
