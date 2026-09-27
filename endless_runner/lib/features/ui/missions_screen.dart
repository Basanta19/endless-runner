import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import '../../core/missions.dart';
import 'app_widgets.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  static const Color _gemColor = Color(0xFF29B6F6);
  final GameData _gd = GameData();

  void _claim(int index) {
    final tierBefore = _gd.missionTier;
    if (!_gd.claimMission(index)) return;
    // The diamond badge animates the "+N" gain itself
    setState(() {});

    if (_gd.missionTier > tierBefore) {
      showInfoPopup(
        context,
        'All missions complete!\nTier ${_gd.missionTier} unlocked',
        icon: Icons.emoji_events_rounded,
      );
    }
  }

  void _showAlreadyClaimed() {
    showInfoPopup(
      context,
      'Reward already claimed',
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'MISSIONS',
                trailing: _AnimatedGemBadge(value: _gd.gems),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _tierBanner(),
                    AppSectionHeader(
                      title: 'TIER ${_gd.missionTier} • '
                          '${_gd.missionReward} GEMS EACH',
                    ),
                    for (int i = 0; i < Missions.all.length; i++)
                      _missionTile(i),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierBanner() {
    final claimed = _gd.missionClaimed.where((c) => c).length;
    final total = Missions.all.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TIER ${_gd.missionTier}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '$claimed / $total CLAIMED',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _progressBar(claimed / total, AppColors.gold),
          const SizedBox(height: 8),
          const Text(
            'Complete every mission to unlock the next tier with doubled goals and bigger rewards.',
            style: TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _missionTile(int i) {
    final def = Missions.all[i];
    final target = _gd.missionTarget(i);
    final progress = _gd.missionProgress[i];
    final claimed = _gd.missionClaimed[i];
    final canClaim = _gd.canClaimMission(i);

    return AppActionTile(
      title: def.title(target),
      subtitle: claimed ? 'COMPLETED' : '$progress / $target',
      leading: Icon(
        def.icon,
        color: def.type == MissionType.coins ? AppColors.gold : Colors.white,
        size: 24,
      ),
      bottom: _progressBar(
        progress / target,
        claimed ? AppColors.green : AppColors.lightBlue,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: claimed
            ? const Icon(Icons.check_circle, color: AppColors.green, size: 28)
            : canClaim
                ? GestureDetector(
                    onTap: () => _claim(i),
                    child: _rewardChip(gradient: AppColors.greenBtn),
                  )
                : Opacity(
                    opacity: 0.5,
                    child: _rewardChip(color: AppColors.panelDark),
                  ),
      ),
      onTap: canClaim
          ? () => _claim(i)
          : claimed
              ? _showAlreadyClaimed
              : null,
    );
  }

  Widget _rewardChip({Gradient? gradient, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: _gemColor, size: 14),
          const SizedBox(width: 4),
          Text(
            gradient != null
                ? 'CLAIM ${_gd.missionReward}'
                : '${_gd.missionReward}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double fraction, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: Colors.white12,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Diamond total that counts up and shows a floating "+N" when it increases.
class _AnimatedGemBadge extends StatefulWidget {
  final int value;
  const _AnimatedGemBadge({required this.value});

  @override
  State<_AnimatedGemBadge> createState() => _AnimatedGemBadgeState();
}

class _AnimatedGemBadgeState extends State<_AnimatedGemBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late int _from = widget.value;
  int _gain = 0;

  @override
  void didUpdateWidget(_AnimatedGemBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value) {
      _from = _displayed(oldWidget.value);
      _gain = widget.value - oldWidget.value;
      _ctrl.forward(from: 0);
    }
  }

  int _displayed(int fallback) {
    if (!_ctrl.isAnimating) return fallback;
    final t = Curves.easeOut.transform(_ctrl.value);
    return (_from + (widget.value - _from) * t).round();
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
        final shown = animating ? _displayed(widget.value) : widget.value;
        // Quick pop when the diamonds land
        final pop = animating ? math.sin(t * math.pi) * 0.15 : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + pop,
              child: AppCoinBadge(
                value: '$shown',
                color: _MissionsScreenState._gemColor,
                icon: Icons.diamond,
              ),
            ),
            if (animating)
              Positioned(
                right: 8,
                // Rises from below the badge up into it
                top: 36 - 32 * Curves.easeOut.transform(t),
                child: Opacity(
                  opacity: t < 0.75 ? 1 : ((1 - t) / 0.25).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+$_gain',
                        style: const TextStyle(
                          color: _MissionsScreenState._gemColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.diamond,
                        color: _MissionsScreenState._gemColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
