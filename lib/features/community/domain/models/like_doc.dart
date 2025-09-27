class LikeDoc {
  const LikeDoc({
    required this.id,
    required this.postId,
    required this.uid,
    required this.createdAt,
  });

  final String id; // composite key: postId_uid
  final String postId;
  final String uid;
  final DateTime createdAt;

  LikeDoc copyWith({String? postId, String? uid, DateTime? createdAt}) =>
      LikeDoc(
        id: id,
        postId: postId ?? this.postId,
        uid: uid ?? this.uid,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'postId': postId,
    'uid': uid,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  static LikeDoc fromJson(String id, Map<String, Object?> json) => LikeDoc(
    id: id,
    postId: (json['postId'] as String?) ?? '',
    uid: (json['uid'] as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      ((json['createdAt'] as num?) ?? 0).toInt(),
    ),
  );
}
