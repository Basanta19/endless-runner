/// Dynamic Difficulty Adjustment (DDA).
///
/// Estimates the player's current skill from their most recent runs and turns
/// it into a difficulty factor:
///   < 1.0  easier  (player keeps dying early)
///   = 1.0  normal  (no history yet, or average player)
///   > 1.0  harder  (player regularly goes far)
///
/// Skill = exponentially weighted average of recent run scores: the newest
/// run has weight 1, the one before it [decay], then decay², and so on,
/// divided by the total weight. Newer runs always count more, so the game
/// reacts to how the player is doing *now*, but a single lucky or unlucky
/// run can't swing it.
///
/// (A plain running EMA seeded with the oldest run is avoided on purpose:
/// with only a few samples the oldest run would outweigh the newest.)
class DifficultyAdjuster {
  /// How many recent runs to look at.
  static const int sampleSize = 5;

  /// Weight multiplier per step back in time (0..1). Lower = reacts faster.
  static const double decay = 0.8;

  /// Average scores at which difficulty bottoms out / tops out.
  static const double easyScore = 1500; // ~25s runs
  static const double hardScore = 8000; // ~2+ min runs

  static const double minFactor = 0.8;
  static const double maxFactor = 1.25;

  /// Exponentially weighted average of [scoresOldestFirst].
  static double skillEstimate(List<int> scoresOldestFirst) {
    if (scoresOldestFirst.isEmpty) return double.nan;
    double weight = 1.0; // newest run
    double weightedSum = 0;
    double totalWeight = 0;
    for (final score in scoresOldestFirst.reversed) {
      weightedSum += weight * score;
      totalWeight += weight;
      weight *= decay;
    }
    return weightedSum / totalWeight;
  }

  /// Difficulty factor for the given recent scores (oldest → newest).
  static double factorFor(List<int> scoresOldestFirst) {
    final skill = skillEstimate(scoresOldestFirst);
    if (skill.isNaN) return 1.0; // no history: normal difficulty

    // Linear interpolation between the easy and hard score points
    final t = ((skill - easyScore) / (hardScore - easyScore)).clamp(0.0, 1.0);
    return minFactor + (maxFactor - minFactor) * t;
  }
}
