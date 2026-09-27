import 'package:flutter/material.dart';
import 'package:runner_rush/features/ui/app_widgets.dart';
import 'package:runner_rush/features/ui/leaderboard_screen.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import 'game_screen.dart';
import 'character_screen.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart'; // This will remain named StoreScreen for now but I'll update the title

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleCtrl;
  late Animation<double> _idleBob;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _idleBob = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));

    // Show the daily reward popup on the first open of the day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && GameData().canClaimDailyReward) _showDailyRewardDialog();
    });
  }

  void _onDailyRewardTap() {
    if (GameData().canClaimDailyReward) {
      _showDailyRewardDialog();
    } else {
      showInfoPopup(
        context,
        'Reward already claimed\nCome back tomorrow!',
        icon: Icons.card_giftcard,
      );
    }
  }

  void _showDailyRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
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
                'DAILY REWARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.card_giftcard,
                  color: AppColors.orange, size: 64),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: AppColors.gold, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '${GameData.dailyRewardAmount}',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Come back every day for more coins!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'CLAIM',
                gradient: AppColors.greenBtn,
                onTap: () {
                  GameData().claimDailyReward();
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gd = GameData();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                          color: AppColors.panelMid,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.panelDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        gd.nickname.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _currencyBadge(Icons.circle, '${gd.coins}', AppColors.gold),
                    const SizedBox(width: 8),
                    _currencyBadge(
                      Icons.diamond,
                      '${gd.gems}',
                      const Color(0xFF29B6F6),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => showInfoPopup(
                        context,
                        'Coming soon!',
                        icon: Icons.storefront_rounded,
                      ),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.mediumBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Stack(
                  children: [
                    // Road/city background
                    Positioned.fill(child: _buildBackground()),

                    // Left side menu buttons
                    Positioned(
                      left: 12,
                      top: 20,
                      child: Column(
                        children: [
                          _menuBtn(Icons.person_pin, 'CHARACTERS', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CharacterScreen(),
                              ),
                            ).then((_) => setState(() {}));
                          }),
                          const SizedBox(height: 10),
                          _menuBtn(
                              Icons.auto_awesome_motion_rounded, 'UPGRADES',
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StoreScreen(),
                              ),
                            ).then((_) => setState(() {}));
                          }),
                        ],
                      ),
                    ),

                    // Right side menu buttons
                    Positioned(
                      right: 12,
                      top: 20,
                      child: Column(
                        children: [
                          _specialBtn(
                            Icons.card_giftcard,
                            'DAILY\nREWARD',
                            AppColors.orange,
                            onTap: _onDailyRewardTap,
                            showDot: gd.canClaimDailyReward,
                          ),
                          const SizedBox(height: 10),
                          _specialBtn(
                            Icons.assignment_rounded,
                            'MISSIONS',
                            AppColors.mediumBlue,
                            showDot: gd.hasClaimableMission,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MissionsScreen(),
                                ),
                              ).then((_) => setState(() {}));
                            },
                          ),
                        ],
                      ),
                    ),

                    // Logo
                    const Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'RUNNER',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                            Text(
                              'RUSH',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gold,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Character centered
                    Positioned(
                      bottom: 140,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _idleBob,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, _idleBob.value),
                            child: _buildCharacterPreview(),
                          ),
                        ),
                      ),
                    ),

                    // Play button
                    Positioned(
                      bottom: 60,
                      left: 60,
                      right: 60,
                      child: GradientButton(
                        label: 'PLAY',
                        gradient: AppColors.playBtn,
                        fontSize: 26,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GameScreen(),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom nav
              BottomNavBar(
                onHome: () {},
                onLeaderboard: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  ).then((_) => setState(() {}));
                },
                onSettings: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return CustomPaint(painter: _HomeBgPainter());
  }

  Widget _buildCharacterPreview() {
    final color = GameData.characterBodyColors[GameData().selectedCharacter];
    return CustomPaint(
      size: const Size(100, 160),
      painter: _CharPreviewPainter(color),
    );
  }

  Widget _menuBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.panelMid.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _specialBtn(IconData icon, String label, Color color,
      {VoidCallback? onTap, bool showDot = false}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _specialBtnBody(icon, label, color),
          // "Ready to claim" indicator
          if (showDot)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _specialBtnBody(IconData icon, String label, Color color) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _currencyBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1B3A6B), Color(0xFF0D1B2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    // Road at bottom
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      Paint()..color = const Color(0xFF3D3D3D),
    );
    // Lane lines
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    final dashPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2;
    for (final x in [size.width * 0.33, size.width * 0.66]) {
      double y = size.height * 0.6;
      while (y < size.height) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 24), dashPaint);
        y += 44;
      }
    }
    // Pavement border
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CharPreviewPainter extends CustomPainter {
  final Color bodyColor;
  _CharPreviewPainter(this.bodyColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final skin = Paint()..color = const Color(0xFFFFC299);
    final body = Paint()..color = bodyColor;
    final pants = Paint()..color = const Color(0xFF1565C0);
    final shoes = Paint()..color = const Color(0xFF212121);
    final hair = Paint()..color = const Color(0xFF4A2800);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 6),
        width: 54,
        height: 14,
      ),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Shoes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 12, size.height - 16),
          width: 24,
          height: 12,
        ),
        const Radius.circular(5),
      ),
      shoes,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 12, size.height - 16),
          width: 24,
          height: 12,
        ),
        const Radius.circular(5),
      ),
      shoes,
    );
    // Shoe accent (white stripe)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 12, size.height - 18),
          width: 18,
          height: 3,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 12, size.height - 18),
          width: 18,
          height: 3,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white54,
    );

    // Legs/pants
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 10, size.height - 40),
          width: 20,
          height: 44,
        ),
        const Radius.circular(6),
      ),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 10, size.height - 40),
          width: 20,
          height: 44,
        ),
        const Radius.circular(6),
      ),
      pants,
    );

    // Body/hoodie
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height - 80),
          width: 54,
          height: 52,
        ),
        const Radius.circular(10),
      ),
      body,
    );
    // Hoodie pocket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height - 64),
          width: 28,
          height: 16,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = bodyColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Arms
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 32, size.height - 82),
          width: 16,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 32, size.height - 82),
          width: 16,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      body,
    );

    // Neck
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, size.height - 110),
        width: 16,
        height: 10,
      ),
      skin,
    );

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height - 128),
          width: 44,
          height: 40,
        ),
        const Radius.circular(12),
      ),
      skin,
    );

    // Hair
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 22, size.height - 152, 44, 20),
        const Radius.circular(10),
      ),
      hair,
    );
    // Hair spikes
    final spike = Path()
      ..moveTo(cx - 6, size.height - 152)
      ..lineTo(cx, size.height - 166)
      ..lineTo(cx + 8, size.height - 152)
      ..close();
    canvas.drawPath(spike, hair);

    // Eyes
    canvas.drawCircle(
      Offset(cx - 9, size.height - 128),
      5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + 9, size.height - 128),
      5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx - 8, size.height - 128),
      3,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(cx + 10, size.height - 128),
      3,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(cx - 7, size.height - 130),
      1,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + 11, size.height - 130),
      1,
      Paint()..color = Colors.white,
    );

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height - 118),
        width: 16,
        height: 8,
      ),
      0,
      3.14,
      false,
      Paint()
        ..color = const Color(0xFFCC8866)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CharPreviewPainter old) => old.bodyColor != bodyColor;
}
