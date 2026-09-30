import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import 'app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: GameData().nickname);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        GameData().nickname = _nameController.text.trim();
        GameData().save();
        _isEditing = false;
      });
      showInfoPopup(
        context,
        'Nickname updated!',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = GameData();

    return Scaffold(
      backgroundColor: AppColors.panelDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.panelDark,
              AppColors.panelMid.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'PLAYER PROFILE'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Avatar Area
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.panelMid,
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Nickname Card
                      _buildSectionCard(
                        title: 'NICKNAME',
                        child: Row(
                          children: [
                            Expanded(
                              child: _isEditing
                                  ? TextField(
                                      controller: _nameController,
                                      style: GoogleFonts.inter(
                                          color: Colors.white),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter name...',
                                        hintStyle:
                                            TextStyle(color: Colors.white38),
                                      ),
                                      autofocus: true,
                                      onSubmitted: (_) => _saveName(),
                                    )
                                  : Text(
                                      data.nickname,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.check_circle : Icons.edit,
                                color: _isEditing
                                    ? Colors.greenAccent
                                    : AppColors.gold,
                              ),
                              onPressed: () {
                                if (_isEditing) {
                                  _saveName();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats Card
                      _buildSectionCard(
                        title: 'STATISTICS',
                        child: Column(
                          children: [
                            _buildStatRow('BEST SCORE',
                                data.highScore.toString(), AppColors.gold),
                            const Divider(color: Colors.white10),
                            _buildStatRow('TOTAL COINS', data.coins.toString(),
                                Colors.yellowAccent),
                            const Divider(color: Colors.white10),
                            _buildStatRow('TOTAL GEMS', data.gems.toString(),
                                Colors.cyanAccent),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      GradientButton(
                        label: 'BACK TO MENU',
                        onTap: () => Navigator.pop(context),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF457B9D), Color(0xFF1D3557)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
