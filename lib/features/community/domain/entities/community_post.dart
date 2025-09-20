import 'package:equatable/equatable.dart';

import '../../../profile/domain/career_track.dart';

enum CommunityAudience { global, track }

class CommunityPost extends Equatable {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorTrack,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.audience,
    this.targetTrack,
  });

  final String id;
  final String authorName;
  final CareerTrack authorTrack;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final CommunityAudience audience;
  final CareerTrack? targetTrack;

  bool get isGlobal => audience == CommunityAudience.global;

  @override
  List<Object?> get props => [
    id,
    authorName,
    authorTrack,
    content,
    createdAt,
    likes,
    comments,
    audience,
    targetTrack,
  ];
}
