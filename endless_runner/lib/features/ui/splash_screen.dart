import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import '../../services/audio_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progress;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressCtrl.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await GameData().load();
        await AudioService().init();
        await _fadeCtrl.forward();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    });
    // Hold the starting sliver briefly so it's visible, then start filling
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _progressCtrl.forward();
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(_fadeCtrl),
          child: Stack(
            children: [
              // City background silhouette
              Positioned(
                bottom: 200,
                left: 0,
                right: 0,
                child: _buildCityscape(),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFB0D4FF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'RUNNER',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFCC02), Color(0xFFFF6F00)],
                          ).createShader(bounds),
                          child: const Text(
                            'RUSH',
                            style: TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_left,
                                color: AppColors.gold,
                                size: 18,
                              ),
                              Text(
                                ' ENDLESS RUNNER ',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 14,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.arrow_right,
                                color: AppColors.gold,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Loading bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) => Text(
                              'LOADING... ${(_progress.value * 100).toInt()}%',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            // Full-width track so the fill grows from the left
                            width: double.infinity,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.panelDark,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (_, __) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                // Start with a 5% sliver, then grow to full
                                widthFactor: 0.05 + 0.95 * _progress.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.gold,
                                        AppColors.orange,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCityscape() {
    return CustomPaint(
      size: const Size(double.infinity, 160),
      painter: _CityscapePainter(),
    );
  }
}

class _CityscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0A1525);
    final buildings = [
      [0.0, 0.3, 0.1, 0.7],
      [0.08, 0.15, 0.08, 0.85],
      [0.15, 0.1, 0.1, 0.9],
      [0.24, 0.3, 0.08, 0.7],
      [0.31, 0.05, 0.12, 0.95],
      [0.42, 0.2, 0.1, 0.8],
      [0.5, 0.08, 0.1, 0.92],
      [0.6, 0.25, 0.09, 0.75],
      [0.68, 0.12, 0.11, 0.88],
      [0.79, 0.3, 0.1, 0.7],
      [0.88, 0.18, 0.12, 0.82],
    ];
    for (final b in buildings) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * b[0],
          size.height * b[1],
          size.width * b[2],
          size.height * b[3],
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
