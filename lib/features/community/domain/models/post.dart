import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../profile/domain/career_track.dart';

enum PostType { chirp, board }

enum PostAudience { all, serial }

enum PostVisibility { public, hidden, deleted }

class PostMedia extends Equatable {
  const PostMedia({
    required this.path,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
  });

  final String path;
  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'path': path,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'w': width,
      'h': height,
    };
  }

  static PostMedia fromMap(Map<String, Object?> data) {
    return PostMedia(
      path: (data['path'] as String?) ?? '',
      url: (data['url'] as String?) ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      width: (data['w'] as num?)?.toInt(),
      height: (data['h'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => <Object?>[path, url, thumbnailUrl, width, height];
}

class CachedComment extends Equatable {
  const CachedComment({
    required this.id,
    required this.text,
    required this.likeCount,
    required this.authorNickname,
  });

  final String id;
  final String text;
  final int likeCount;
  final String authorNickname;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'text': text,
      'likeCount': likeCount,
      'authorNickname': authorNickname,
    };
  }

  static CachedComment? fromMap(Map<String, Object?>? data) {
    if (data == null) {
      return null;
    }

    final String? id = data['id'] as String?;
    final String? text = data['text'] as String?;
    final int likeCount = (data['likeCount'] as num?)?.toInt() ?? 0;
    final String? authorNickname = data['authorNickname'] as String?;
    if (id == null || text == null || authorNickname == null) {
      return null;
    }

    return CachedComment(
      id: id,
      text: text,
      likeCount: likeCount,
      authorNickname: authorNickname,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, text, likeCount, authorNickname];
}

class Post extends Equatable {
  const Post({
    required this.id,
    required this.type,
    required this.audience,
    required this.serial,
    required this.boardId,
    required this.authorUid,
    required this.authorNickname,
    required this.authorTrack,
    required this.text,
    required this.media,
    required this.tags,
    required this.keywords,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.hotScore,
    required this.createdAt,
    required this.updatedAt,
    required this.visibility,
    this.topComment,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  final String id;
  final PostType type;
  final PostAudience audience;
  final String serial;
  final String? boardId;
  final String authorUid;
  final String authorNickname;
  final CareerTrack authorTrack;
  final String text;
  final List<PostMedia> media;
  final List<String> tags;
  final List<String> keywords;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final double hotScore;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final PostVisibility visibility;
  final CachedComment? topComment;
  final bool isLiked;
  final bool isBookmarked;

  bool get isHidden => visibility != PostVisibility.public;

  bool get hasMedia => media.isNotEmpty;

  bool get isChirp => type == PostType.chirp;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'audience': audience.name,
      'serial': serial,
      'boardId': boardId,
      'authorUid': authorUid,
      'authorNickname': authorNickname,
      'authorTrack': authorTrack.name,
      'text': text,
      'media': media.map((PostMedia media) => media.toMap()).toList(growable: false),
      'tags': tags,
      'keywords': keywords,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'hotScore': hotScore,
      'topComment': topComment?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'visibility': visibility.name,
    };
  }

  static Post fromSnapshot(DocumentSnapshot<Map<String, Object?>> snapshot, {bool isLiked = false, bool isBookmarked = false}) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('Post document ${snapshot.id} has no data');
    }

    return fromMap(snapshot.id, data, isLiked: isLiked, isBookmarked: isBookmarked);
  }

  static Post fromMap(
    String id,
    Map<String, Object?> data, {
    bool isLiked = false,
    bool isBookmarked = false,
  }) {
    return Post(
      id: id,
      type: _parseType(data['type']),
      audience: _parseAudience(data['audience']),
      serial: (data['serial'] as String?) ?? 'all',
      boardId: data['boardId'] as String?,
      authorUid: (data['authorUid'] as String?) ?? '',
      authorNickname: (data['authorNickname'] as String?) ?? '익명',
      authorTrack: _parseTrack(data['authorTrack']),
      text: (data['text'] as String?) ?? '',
      media: _parseMedia(data['media']),
      tags: _parseStringList(data['tags']),
      keywords: _parseStringList(data['keywords']),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      hotScore: (data['hotScore'] as num?)?.toDouble() ?? 0,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      visibility: _parseVisibility(data['visibility']),
      topComment: CachedComment.fromMap(
        (data['topComment'] as Map<String, Object?>?)?.cast<String, Object?>(),
      ),
      isLiked: isLiked,
      isBookmarked: isBookmarked,
    );
  }

  Post copyWith({
    int? likeCount,
    int? commentCount,
    int? viewCount,
    double? hotScore,
    CachedComment? topComment,
    bool? isLiked,
    bool? isBookmarked,
    PostVisibility? visibility,
  }) {
    return Post(
      id: id,
      type: type,
      audience: audience,
      serial: serial,
      boardId: boardId,
      authorUid: authorUid,
      authorNickname: authorNickname,
      authorTrack: authorTrack,
      text: text,
      media: media,
      tags: tags,
      keywords: keywords,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      hotScore: hotScore ?? this.hotScore,
      createdAt: createdAt,
      updatedAt: updatedAt,
      visibility: visibility ?? this.visibility,
      topComment: topComment ?? this.topComment,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  static PostType _parseType(Object? raw) {
    if (raw is String) {
      return PostType.values.firstWhere(
        (PostType type) => type.name == raw,
        orElse: () => PostType.chirp,
      );
    }
    return PostType.chirp;
  }

  static PostAudience _parseAudience(Object? raw) {
    if (raw is String) {
      return PostAudience.values.firstWhere(
        (PostAudience audience) => audience.name == raw,
        orElse: () => PostAudience.all,
      );
    }
    return PostAudience.all;
  }

  static PostVisibility _parseVisibility(Object? raw) {
    if (raw is String) {
      return PostVisibility.values.firstWhere(
        (PostVisibility visibility) => visibility.name == raw,
        orElse: () => PostVisibility.public,
      );
    }
    return PostVisibility.public;
  }

  static CareerTrack _parseTrack(Object? raw) {
    if (raw is String) {
      return CareerTrack.values.firstWhere(
        (CareerTrack track) => track.name == raw,
        orElse: () => CareerTrack.none,
      );
    }
    return CareerTrack.none;
  }

  static List<PostMedia> _parseMedia(Object? raw) {
    if (raw is Iterable) {
      return raw
          .whereType<Map<String, Object?>>()
          .map(PostMedia.fromMap)
          .toList(growable: false);
    }
    return const <PostMedia>[];
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is Iterable) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return null;
  }

  static String randomShardId({int max = 20}) {
    final int index = Random().nextInt(max);
    return 'shard_$index';
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    type,
    audience,
    serial,
    boardId,
    authorUid,
    authorNickname,
    authorTrack,
    text,
    media,
    tags,
    keywords,
    likeCount,
    commentCount,
    viewCount,
    hotScore,
    createdAt,
    updatedAt,
    visibility,
    topComment,
    isLiked,
    isBookmarked,
  ];
}
