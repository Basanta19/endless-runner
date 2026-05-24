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
                      const Icon(Icons.shield_rounded, color: AppColors.gold, size: 24),
                    ),
                    _upgradeTile(
                      'SPEED BOOST',
                      'Invincibility • +2s/lvl',
                      _gd.speedLevel,
                      () => _upgrade('SPEED'),
                      const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 24),
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

  Widget _upgradeTile(
      String title, String desc, int level, VoidCallback onTap, Widget leading) {
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
      bottom: Row(
        children: List.generate(GameData.maxPowerUpLevel, (i) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i < level ? AppColors.green : Colors.white12,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$type upgraded!')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not enough coins!')));
    }
  }
}
