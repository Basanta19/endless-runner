import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../runner_game.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import 'pause_menu.dart';
import 'game_over.dart';
import 'respawn_overlay.dart';
import '../../core/game_state.dart';
import '../../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RunnerGame _game;
  bool _gameOver = false;
  bool _respawnOffer = false;
  bool _showHint = true;
  Timer? _hintTimer;

  /// Shows the controls hint for 1 second at the start of each run.
  void _startHint() {
    _hintTimer?.cancel();
    if (mounted) setState(() => _showHint = true);
    _hintTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

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
    _game.onCrash = () => _safeSetState(() => _respawnOffer = true);
    _startHint();
  }

  void _onRespawn() {
    setState(() => _respawnOffer = false);
    if (!_game.respawn()) _game.finalizeGameOver();
  }

  void _onRespawnDeclined() {
    setState(() => _respawnOffer = false);
    _game.finalizeGameOver();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _game.pauseEngine();
    // Persist mission progress if the player quits mid-run
    GameData().save();
    // Stop audio when exiting the game screen to prevent overlaying
    AudioService().stopBgm();
    super.dispose();
  }

  void _onPause() {
    // No pausing during the respawn countdown or after game over
    if (_game.gameState != RunnerGameState.playing) return;
    _game.pauseGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        // Device back button on the pause menu = resume
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.pop(context);
          _game.resumeGame();
        },
        child: PauseMenuDialog(
          onResume: () {
            Navigator.pop(context);
            _game.resumeGame();
          },
          onRestart: () {
            Navigator.pop(context);
            _safeSetState(() => _gameOver = false);
            _game.restartGame();
            _startHint();
          },
          onHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onExit: () => SystemNavigator.pop(),
        ),
      ),
    );
  }

  /// Device back button during a run: pause instead of leaving the game.
  void _onBackPressed() {
    switch (_game.gameState) {
      case RunnerGameState.playing:
        _onPause();
        break;
      case RunnerGameState.gameOver:
        // On the Game Over screen, back goes home like the HOME button
        _game.pauseEngine();
        Navigator.pop(context);
        break;
      default:
        // Respawn countdown / loading: ignore
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: _buildGame(context),
    );
  }

  Widget _buildGame(BuildContext context) {
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
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showHint && !_gameOver ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Center(
                  child: Text(
                    '← SWIPE TO DODGE →   ↑ SWIPE UP TO JUMP   ↓ SWIPE DOWN TO SLIDE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  ),
                ),
              ),
            ),
          ),

          // ── Respawn offer (3s) ─────────────────────────────────────────
          if (_respawnOffer)
            Positioned.fill(
              child: RespawnOverlay(
                cost: _game.respawnCost,
                onRespawn: _onRespawn,
                onTimeout: _onRespawnDeclined,
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
                  _startHint();
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
