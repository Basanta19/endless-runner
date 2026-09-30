import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';

/// Shown right after a crash: tap RESPAWN within [seconds] to continue the
/// run for [cost] gems, otherwise [onTimeout] ends the run.
class RespawnOverlay extends StatefulWidget {
  final int cost;
  final int seconds;
  final VoidCallback onRespawn;
  final VoidCallback onTimeout;

  const RespawnOverlay({
    super.key,
    required this.cost,
    required this.onRespawn,
    required this.onTimeout,
    this.seconds = 3,
  });

  @override
  State<RespawnOverlay> createState() => _RespawnOverlayState();
}

class _RespawnOverlayState extends State<RespawnOverlay>
    with SingleTickerProviderStateMixin {
  static const Color _gemColor = Color(0xFF29B6F6);
  late final AnimationController _ctrl;
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _decide(widget.onTimeout);
      })
      ..forward();
  }

  /// Makes sure only one of respawn / timeout / skip ever fires.
  void _decide(VoidCallback action) {
    if (_decided) return;
    _decided = true;
    _ctrl.stop();
    action();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
          decoration: BoxDecoration(
            color: AppColors.panelDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONTINUE?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),

              // Countdown ring
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final remaining =
                      (widget.seconds * (1 - _ctrl.value)).ceil().clamp(
                            1,
                            widget.seconds,
                          );
                  return SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 1 - _ctrl.value,
                          strokeWidth: 7,
                          backgroundColor: Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.orange),
                        ),
                        Center(
                          child: Text(
                            '$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // Respawn button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _decide(widget.onRespawn),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.greenBtn,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RESPAWN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.diamond, color: _gemColor, size: 18),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.cost}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have ${GameData().gems} diamonds',
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              TextButton(
                onPressed: () => _decide(widget.onTimeout),
                child: const Text(
                  'NO THANKS',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
