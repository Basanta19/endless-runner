import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/audio_service.dart';

class PauseMenuDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onExit;

  const PauseMenuDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
    required this.onExit,
  });

  @override
  State<PauseMenuDialog> createState() => _PauseMenuDialogState();
}

class _PauseMenuDialogState extends State<PauseMenuDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.panelDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            _pauseBtn(
              'RESUME',
              Icons.play_arrow_rounded,
              AppColors.greenBtn,
              widget.onResume,
            ),
            const SizedBox(height: 10),
            _pauseBtn(
              'RESTART',
              Icons.refresh_rounded,
              AppColors.blueBtn,
              widget.onRestart,
            ),
            const SizedBox(height: 10),
            _pauseBtn(
                'HOME', Icons.home_rounded, AppColors.yellowBtn, widget.onHome),
            const SizedBox(height: 10),
            _pauseBtn(
              'EXIT',
              Icons.exit_to_app_rounded,
              AppColors.redBtn,
              widget.onExit,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconToggle(
                  AudioService().isSfxEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  AudioService().isSfxEnabled,
                  () => setState(() => AudioService().toggleSfx()),
                ),
                const SizedBox(width: 16),
                _iconToggle(
                  AudioService().isMusicEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  AudioService().isMusicEnabled,
                  () => setState(() => AudioService().toggleMusic()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pauseBtn(
    String label,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconToggle(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.panelMid
              : AppColors.panelMid.withValues(alpha: .5),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.cardBorder : Colors.white24,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white38,
          size: 24,
        ),
      ),
    );
  }
}
