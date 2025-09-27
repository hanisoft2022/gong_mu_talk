import '../../domain/models/comment.dart';
import '../../../profile/domain/career_track.dart';

class DummyCommentSeed {
  const DummyCommentSeed({
    required this.author,
    required this.text,
    required this.likes,
    required this.track,
    this.supporterLevel = 0,
  });

  final String author;
  final String text;
  final int likes;
  final CareerTrack track;
  final int supporterLevel;

  bool get isSupporter => supporterLevel > 0;
}

class CachedComment {
  const CachedComment({required this.comment, required this.likeCount});

  final Comment comment;
  final int likeCount;
}
