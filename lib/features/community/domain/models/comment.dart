import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../profile/domain/career_track.dart';

class Comment extends Equatable {
  static const Object _unset = Object();

  const Comment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorNickname,
    required this.authorTrack,
    required this.authorSerialVisible,
    required this.text,
    required this.likeCount,
    required this.createdAt,
    this.parentCommentId,
    this.deleted = false,
    this.isLiked = false,
    this.reactionCounts = const <String, int>{},
    this.viewerReaction,
    this.authorSupporterLevel = 0,
    this.authorIsSupporter = false,
  });

  final String id;
  final String postId;
  final String authorUid;
  final String authorNickname;
  final CareerTrack authorTrack;
  final bool authorSerialVisible;
  final String text;
  final int likeCount;
  final DateTime createdAt;
  final String? parentCommentId;
  final bool deleted;
  final bool isLiked;
  final Map<String, int> reactionCounts;
  final String? viewerReaction;
  final int authorSupporterLevel;
  final bool authorIsSupporter;

  bool get isReply => parentCommentId != null && parentCommentId!.isNotEmpty;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'authorUid': authorUid,
      'authorNickname': authorNickname,
      'authorTrack': authorTrack.name,
      'authorSerialVisible': authorSerialVisible,
      'authorSupporterLevel': authorSupporterLevel,
      'authorIsSupporter': authorIsSupporter,
      'text': text,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentCommentId': parentCommentId,
      'deleted': deleted,
      'reactionCounts': reactionCounts,
    };
  }

  static Comment fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snapshot, {
    String? postId,
    bool isLiked = false,
    String? viewerReaction,
  }) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('Comment document ${snapshot.id} has no data');
    }

    return fromMap(
      id: snapshot.id,
      postId: postId ?? snapshot.reference.parent.parent?.id ?? '',
      data: data,
      isLiked: isLiked,
      viewerReaction: viewerReaction,
    );
  }

  static Comment fromMap({
    required String id,
    required String postId,
    required Map<String, Object?> data,
    bool isLiked = false,
    String? viewerReaction,
  }) {
    return Comment(
      id: id,
      postId: postId,
      authorUid: (data['authorUid'] as String?) ?? '',
      authorNickname: (data['authorNickname'] as String?) ?? '익명',
      authorTrack: _parseTrack(data['authorTrack']),
      authorSerialVisible: data['authorSerialVisible'] as bool? ?? true,
      text: (data['text'] as String?) ?? '',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      parentCommentId: data['parentCommentId'] as String?,
      deleted: data['deleted'] as bool? ?? false,
      isLiked: isLiked,
      reactionCounts: _parseReactionCounts(
        (data['reactionCounts'] as Map<String, Object?>?)
            ?.cast<String, Object?>(),
      ),
      viewerReaction: viewerReaction,
      authorSupporterLevel:
          (data['authorSupporterLevel'] as num?)?.toInt() ?? 0,
      authorIsSupporter:
          data['authorIsSupporter'] as bool? ??
          ((data['authorSupporterLevel'] as num?)?.toInt() ?? 0) > 0,
    );
  }

  Comment copyWith({
    String? text,
    int? likeCount,
    bool? deleted,
    bool? isLiked,
    Map<String, int>? reactionCounts,
    Object? viewerReaction = _unset,
    CareerTrack? authorTrack,
    bool? authorSerialVisible,
    int? authorSupporterLevel,
    bool? authorIsSupporter,
  }) {
    return Comment(
      id: id,
      postId: postId,
      authorUid: authorUid,
      authorNickname: authorNickname,
      authorTrack: authorTrack ?? this.authorTrack,
      authorSerialVisible: authorSerialVisible ?? this.authorSerialVisible,
      text: text ?? this.text,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt,
      parentCommentId: parentCommentId,
      deleted: deleted ?? this.deleted,
      isLiked: isLiked ?? this.isLiked,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      viewerReaction: viewerReaction == _unset
          ? this.viewerReaction
          : viewerReaction as String?,
      authorSupporterLevel: authorSupporterLevel ?? this.authorSupporterLevel,
      authorIsSupporter: authorIsSupporter ?? this.authorIsSupporter,
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    postId,
    authorUid,
    authorNickname,
    authorTrack,
    authorSerialVisible,
    text,
    likeCount,
    createdAt,
    parentCommentId,
    deleted,
    isLiked,
    reactionCounts,
    viewerReaction,
    authorSupporterLevel,
    authorIsSupporter,
  ];

  static CareerTrack _parseTrack(Object? raw) {
    if (raw is String) {
      return CareerTrack.values.firstWhere(
        (CareerTrack track) => track.name == raw,
        orElse: () => CareerTrack.none,
      );
    }
    return CareerTrack.none;
  }

  static Map<String, int> _parseReactionCounts(Map<String, Object?>? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String, int>{};
    }
    return raw.map(
      (String key, Object? value) =>
          MapEntry(key, (value as num?)?.toInt() ?? 0),
    )..removeWhere((_, int count) => count <= 0);
  }
}
