import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../runner_game.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import 'pause_menu.dart';
import 'game_over.dart';
import '../../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RunnerGame _game;
  bool _gameOver = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    // Defer setState to after the current build frame to avoid
    // "setState called during build" errors from Flame game callbacks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  @override
  void initState() {
    super.initState();
    _game = RunnerGame();
    _game.onGameOver = () => _safeSetState(() => _gameOver = true);
  }

  @override
  void dispose() {
    _game.pauseEngine();
    // Stop audio when exiting the game screen to prevent overlaying
    AudioService().stopBgm();
    super.dispose();
  }

  void _onPause() {
    _game.pauseGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PauseMenuDialog(
        onResume: () {
          Navigator.pop(context);
          _game.resumeGame();
        },
        onRestart: () {
          Navigator.pop(context);
          _safeSetState(() => _gameOver = false);
          _game.restartGame();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onExit: () => SystemNavigator.pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Flame game fills the whole screen ──────────────────────────
          GameWidget(game: _game),

          // ── Flutter HUD overlay (pause button + badges) ────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Pause button
                  GestureDetector(
                    onTap: _onPause,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.panelDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.pause,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.scoreNotifier,
                    builder: (context, score, _) {
                      final multiplier = (score ~/ 2500) + 1;
                      return _badge('x$multiplier', AppColors.orange);
                    },
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.scoreNotifier,
                    builder: (context, score, _) =>
                        _badge('$score', Colors.white),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.coinsNotifier,
                    builder: (context, coins, _) =>
                        _iconBadge('$coins', Icons.circle, AppColors.gold),
                  ),
                  const SizedBox(width: 6),
                  _iconBadge('${GameData().gems}', Icons.diamond,
                      const Color(0xFF29B6F6)),
                ],
              ),
            ),
          ),

          // ── Swipe hint ─────────────────────────────────────────────────
          if (!_gameOver && _game.score < 20)
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '← SWIPE TO DODGE →   ↑ SWIPE UP TO JUMP',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                ),
              ),
            ),

          // ── Game Over overlay ──────────────────────────────────────────
          if (_gameOver)
            Positioned.fill(
              child: GameOverOverlay(
                score: _game.score,
                coins: _game.coinsCollected,
                highScore: GameData().highScore,
                multiplier: (_game.score ~/ 2500) + 1,
                onRetry: () {
                  setState(() {
                    _gameOver = false;
                  });
                  _game.restartGame();
                },
                onHome: () {
                  _game.pauseEngine();
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.panelDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _iconBadge(String text, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.panelDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ]),
      );
}
