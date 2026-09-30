import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/database_service.dart';
import '../../core/game_data.dart';
import 'app_widgets.dart';

/// Shows the player's 10 best runs from the local database.
class TopRunsScreen extends StatefulWidget {
  const TopRunsScreen({super.key});

  @override
  State<TopRunsScreen> createState() => _TopRunsScreenState();
}

class _TopRunsScreenState extends State<TopRunsScreen> {
  late final Future<List<RunRecord>> _runs = GameData().topRuns();

  static const List<Color> _medalColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'TOP RUNS'),
              Expanded(
                child: FutureBuilder<List<RunRecord>>(
                  future: _runs,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }
                    final runs = snapshot.data ?? const <RunRecord>[];
                    if (runs.isEmpty) return _emptyState();
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: runs.length,
                      itemBuilder: (_, i) => _runTile(i + 1, runs[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                color: AppColors.textGray, size: 64),
            SizedBox(height: 12),
            Text(
              'No runs yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Play a game and your best runs will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runTile(int rank, RunRecord run) {
    final isMedal = rank <= 3;
    final rankColor = isMedal ? _medalColors[rank - 1] : AppColors.textLight;
    final character = run.character < GameData.characterNames.length
        ? GameData.characterNames[run.character]
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panelMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isMedal ? rankColor.withValues(alpha: 0.6) : AppColors.cardBorder,
          width: isMedal ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withValues(alpha: 0.7)),
            ),
            child: isMedal
                ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 20)
                : Text(
                    '$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 14),

          // Score + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${run.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _detail(Icons.directions_run_rounded, '${run.distance} m',
                        Colors.white70),
                    _detail(Icons.circle, '${run.coins}', AppColors.gold),
                    _detail(Icons.person_rounded, character, Colors.white70),
                  ],
                ),
              ],
            ),
          ),

          // Date
          Text(
            _formatDate(run.playedAt),
            style: const TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 12),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
}
