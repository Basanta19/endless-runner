import 'package:flutter/material.dart';

enum MissionType { distance, coins, dodge, jump, slide, powerUp }

class MissionDef {
  final MissionType type;
  final int baseTarget;
  final IconData icon;
  final String Function(int target) title;

  const MissionDef({
    required this.type,
    required this.baseTarget,
    required this.icon,
    required this.title,
  });
}

class Missions {
  /// Tier 1 targets. Every following tier doubles the previous tier's targets.
  static final List<MissionDef> all = [
    MissionDef(
      type: MissionType.distance,
      baseTarget: 1000,
      icon: Icons.directions_run_rounded,
      title: (t) => 'Reach $t meters',
    ),
    MissionDef(
      type: MissionType.coins,
      baseTarget: 500,
      icon: Icons.circle,
      title: (t) => 'Collect $t coins',
    ),
    MissionDef(
      type: MissionType.dodge,
      baseTarget: 20,
      icon: Icons.alt_route_rounded,
      title: (t) => 'Dodge $t obstacles',
    ),
    MissionDef(
      type: MissionType.jump,
      baseTarget: 50,
      icon: Icons.arrow_upward_rounded,
      title: (t) => 'Jump $t times',
    ),
    MissionDef(
      type: MissionType.slide,
      baseTarget: 40,
      icon: Icons.arrow_downward_rounded,
      title: (t) => 'Slide $t times',
    ),
    MissionDef(
      type: MissionType.powerUp,
      baseTarget: 30,
      icon: Icons.bolt_rounded,
      title: (t) => 'Collect $t power-ups',
    ),
  ];

  /// Score points per meter (score grows ~60 points/sec).
  static const int scorePerMeter = 10;

  /// Tier 1: 5 gems, Tier 2: 15 gems, then +10 per tier.
  static int rewardForTier(int tier) => 5 + (tier - 1) * 10;

  /// Tier 1: base target, Tier 2: x2, Tier 3: x4, ...
  static int targetFor(MissionDef def, int tier) =>
      def.baseTarget * (1 << (tier - 1));
}
