import 'dart:math';

/// Hot score calculator using logarithmic scaling (Reddit/HackerNews style).
///
/// Uses logarithmic scaling for likes and views to reduce gaming/bot abuse:
/// - First 10 likes have same weight as next 100 likes
/// - Prioritizes early engagement
/// - Comments remain linear (discussion is valuable)
///
/// Formula:
///   baseScore = log10(likes+1)*10 + comments*3 + log10(views+1)*0.5
///   hotScore = baseScore * (0.8 ^ (hoursAgo / 24))
///
/// Example scores:
/// - 10 likes, 5 comments, 100 views, 2h ago:
///   base = 10 + 15 + 1 = 26, decay = 0.993, score = 25.8
/// - 100 likes, 10 comments, 1000 views, 2h ago:
///   base = 20 + 30 + 1.5 = 51.5, decay = 0.993, score = 51.1
/// - 1000 likes (bot), 0 comments, 100 views, 2h ago:
///   base = 30 + 0 + 1 = 31, decay = 0.993, score = 30.8
class HotScoreCalculator {
  const HotScoreCalculator({
    this.likeLogScale = 10.0,
    this.commentWeight = 3.0,
    this.viewLogScale = 0.5,
    this.decayFactor = 0.8,
    this.timeDecayHours = 24,
  });

  /// Multiplier for log10(likes + 1)
  final double likeLogScale;

  /// Linear weight for comments (discussion is valuable)
  final double commentWeight;

  /// Multiplier for log10(views + 1)
  final double viewLogScale;

  /// Exponential decay factor (0.8 = 80% after timeDecayHours)
  final double decayFactor;

  /// Hours for one decay cycle
  final double timeDecayHours;

  double calculate({
    required int likeCount,
    required int commentCount,
    required int viewCount,
    required DateTime createdAt,
    DateTime? now,
  }) {
    final DateTime reference = now ?? DateTime.now();
    final Duration age = reference.difference(createdAt);
    final double hours = age.inMinutes / 60.0;

    // Logarithmic scaling for likes (anti-gaming)
    final double voteScore = log(likeCount + 1) / ln10 * likeLogScale;

    // Linear scaling for comments (discussion value)
    final double commentScore = commentCount * commentWeight;

    // Logarithmic scaling for views (engagement signal)
    final double viewScore = log(viewCount + 1) / ln10 * viewLogScale;

    final double baseScore = voteScore + commentScore + viewScore;

    // Exponential time decay
    final double timeDecay = pow(decayFactor, hours / timeDecayHours).toDouble();

    return baseScore * timeDecay;
  }
}
