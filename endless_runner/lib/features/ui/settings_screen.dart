import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import '../../services/audio_service.dart';
import 'app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  final GameData _gd = GameData();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _gd.nickname);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'SETTINGS'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const AppSectionHeader(title: 'AUDIO'),
                    AppActionTile(
                      title: 'MUSIC',
                      leading: const Icon(Icons.music_note,
                          color: AppColors.lightBlue),
                      trailing: Switch(
                        value: _gd.musicEnabled,
                        onChanged: (val) {
                          AudioService().toggleMusic();
                          setState(() {});
                        },
                        activeThumbColor: AppColors.green,
                        activeTrackColor:
                            AppColors.green.withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.white24,
                        inactiveTrackColor: Colors.black26,
                      ),
                    ),
                    AppActionTile(
                      title: 'SOUND EFFECTS',
                      leading: const Icon(Icons.volume_up,
                          color: AppColors.lightBlue),
                      trailing: Switch(
                        value: _gd.sfxEnabled,
                        onChanged: (val) {
                          AudioService().toggleSfx();
                          setState(() {});
                        },
                        activeThumbColor: AppColors.green,
                        activeTrackColor:
                            AppColors.green.withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.white24,
                        inactiveTrackColor: Colors.black26,
                      ),
                    ),
                    const AppSectionHeader(title: 'PROFILE'),
                    _profileEditTile(),
                    const AppSectionHeader(title: 'GAMEPLAY'),
                    AppActionTile(
                      title: 'RESET HIGH SCORE',
                      leading: const Icon(Icons.refresh, color: AppColors.red),
                      onTap: () => _showResetConfirmation(),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textGray),
                    ),
                    const AppSectionHeader(title: 'ABOUT'),
                    const AppActionTile(
                      title: 'VERSION',
                      leading:
                          Icon(Icons.info_outline, color: AppColors.lightBlue),
                      trailing: Text('1.0.0',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const AppActionTile(
                      title: 'DEVELOPER',
                      leading: Icon(Icons.code, color: AppColors.lightBlue),
                      trailing: Text('DEEPMIND TEAM',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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

  Widget _profileEditTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NICKNAME',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    _gd.nickname = val;
                    _gd.save();
                  },
                ),
              ),
              const Icon(Icons.edit, color: AppColors.gold, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panelDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.cardBorder)),
        title: const Text('RESET DATA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'This will reset your high score. Coins and characters will remain. Continue?',
            style: TextStyle(color: AppColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _gd.highScore = 0;
                _gd.save();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('High score reset!')));
            },
            child: const Text('RESET',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
