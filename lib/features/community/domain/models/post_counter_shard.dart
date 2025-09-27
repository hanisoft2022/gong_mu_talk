class PostCounterShard {
  const PostCounterShard({
    required this.id,
    this.likes = 0,
    this.comments = 0,
    this.views = 0,
  });

  final String id; // shard document id
  final int likes;
  final int comments;
  final int views;

  PostCounterShard copyWith({int? likes, int? comments, int? views}) =>
      PostCounterShard(
        id: id,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        views: views ?? this.views,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'likes': likes,
    'comments': comments,
    'views': views,
  };

  static PostCounterShard fromJson(String id, Map<String, Object?> json) =>
      PostCounterShard(
        id: id,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        comments: (json['comments'] as num?)?.toInt() ?? 0,
        views: (json['views'] as num?)?.toInt() ?? 0,
      );
}
