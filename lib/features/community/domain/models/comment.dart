import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorNickname,
    required this.text,
    required this.likeCount,
    required this.createdAt,
    this.parentCommentId,
    this.deleted = false,
    this.isLiked = false,
  });

  final String id;
  final String postId;
  final String authorUid;
  final String authorNickname;
  final String text;
  final int likeCount;
  final DateTime createdAt;
  final String? parentCommentId;
  final bool deleted;
  final bool isLiked;

  bool get isReply => parentCommentId != null && parentCommentId!.isNotEmpty;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'authorUid': authorUid,
      'authorNickname': authorNickname,
      'text': text,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentCommentId': parentCommentId,
      'deleted': deleted,
    };
  }

  static Comment fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snapshot, {
    String? postId,
    bool isLiked = false,
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
    );
  }

  static Comment fromMap({
    required String id,
    required String postId,
    required Map<String, Object?> data,
    bool isLiked = false,
  }) {
    return Comment(
      id: id,
      postId: postId,
      authorUid: (data['authorUid'] as String?) ?? '',
      authorNickname: (data['authorNickname'] as String?) ?? '익명',
      text: (data['text'] as String?) ?? '',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      parentCommentId: data['parentCommentId'] as String?,
      deleted: data['deleted'] as bool? ?? false,
      isLiked: isLiked,
    );
  }

  Comment copyWith({
    String? text,
    int? likeCount,
    bool? deleted,
    bool? isLiked,
  }) {
    return Comment(
      id: id,
      postId: postId,
      authorUid: authorUid,
      authorNickname: authorNickname,
      text: text ?? this.text,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt,
      parentCommentId: parentCommentId,
      deleted: deleted ?? this.deleted,
      isLiked: isLiked ?? this.isLiked,
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
    text,
    likeCount,
    createdAt,
    parentCommentId,
    deleted,
    isLiked,
  ];
}
