import 'dart:math';

class HotScoreCalculator {
  const HotScoreCalculator({
    this.likeWeight = 3,
    this.commentWeight = 5,
    this.viewWeight = 1,
    this.decayLambda = 1.2,
  });

  final double likeWeight;
  final double commentWeight;
  final double viewWeight;
  final double decayLambda;

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
    final double timeDecay = pow(2, hours / decayLambda).toDouble();
    final double base =
        likeCount * likeWeight + commentCount * commentWeight + viewCount * viewWeight;
    if (timeDecay <= 0) {
      return base;
    }
    return base / timeDecay;
  }
}
