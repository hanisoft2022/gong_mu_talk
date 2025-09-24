import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats extends Equatable {
  const UserStats({
    required this.uid,
    this.points = 0,
    this.level = 1,
    this.postsCount = 0,
    this.commentsCount = 0,
    this.likesReceived = 0,
    this.likesGiven = 0,
    this.badges = const [],
    this.joinedAt,
    this.lastActiveAt,
  });

  final String uid;
  final int points;
  final int level;
  final int postsCount;
  final int commentsCount;
  final int likesReceived;
  final int likesGiven;
  final List<String> badges;
  final DateTime? joinedAt;
  final DateTime? lastActiveAt;

  int get pointsToNextLevel {
    final nextLevelPoints = level * 100; // 100 points per level
    return nextLevelPoints - (points % nextLevelPoints);
  }

  double get progressToNextLevel {
    final currentLevelPoints = (level - 1) * 100;
    final nextLevelPoints = level * 100;
    final progress = (points - currentLevelPoints) / (nextLevelPoints - currentLevelPoints);
    return progress.clamp(0.0, 1.0);
  }

  String get levelTitle {
    if (level <= 5) return '새내기';
    if (level <= 10) return '일반직';
    if (level <= 20) return '선임';
    if (level <= 30) return '주임';
    if (level <= 50) return '전문가';
    return '달인';
  }

  UserStats copyWith({
    int? points,
    int? level,
    int? postsCount,
    int? commentsCount,
    int? likesReceived,
    int? likesGiven,
    List<String>? badges,
    DateTime? lastActiveAt,
  }) {
    return UserStats(
      uid: uid,
      points: points ?? this.points,
      level: level ?? this.level,
      postsCount: postsCount ?? this.postsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likesReceived: likesReceived ?? this.likesReceived,
      likesGiven: likesGiven ?? this.likesGiven,
      badges: badges ?? this.badges,
      joinedAt: joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'points': points,
      'level': level,
      'postsCount': postsCount,
      'commentsCount': commentsCount,
      'likesReceived': likesReceived,
      'likesGiven': likesGiven,
      'badges': badges,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  static UserStats fromMap(String uid, Map<String, Object?> data) {
    return UserStats(
      uid: uid,
      points: (data['points'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      postsCount: (data['postsCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      likesReceived: (data['likesReceived'] as num?)?.toInt() ?? 0,
      likesGiven: (data['likesGiven'] as num?)?.toInt() ?? 0,
      badges: (data['badges'] as List<dynamic>?)?.cast<String>() ?? [],
      joinedAt: _parseTimestamp(data['joinedAt']),
      lastActiveAt: _parseTimestamp(data['lastActiveAt']),
    );
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        uid,
        points,
        level,
        postsCount,
        commentsCount,
        likesReceived,
        likesGiven,
        badges,
        joinedAt,
        lastActiveAt,
      ];
}

enum BadgeType {
  firstPost('첫 글 작성자', '첫 번째 게시글을 작성했습니다', '🎉'),
  firstComment('첫 댓글러', '첫 번째 댓글을 작성했습니다', '💬'),
  firstLike('첫 좋아요', '첫 번째 좋아요를 받았습니다', '❤️'),
  popularPost('인기글 작성자', '좋아요 10개 이상받은 글을 작성했습니다', '🔥'),
  activeCommenter('활발한 댓글러', '댓글 50개 이상 작성했습니다', '💭'),
  helpful('도움왕', '좋아요를 많이 받는 댓글을 작성합니다', '👍'),
  consistent('꾸준이', '7일 연속 접속했습니다', '📅'),
  earlyBird('얼리어답터', '서비스 초기 가입자입니다', '🐣'),
  mentor('멘토', '신규 사용자를 도와주었습니다', '🎓'),
  expert('전문가', '특정 분야에서 인정받고 있습니다', '💯');

  const BadgeType(this.title, this.description, this.emoji);

  final String title;
  final String description;
  final String emoji;

  static BadgeType? fromString(String value) {
    return BadgeType.values
        .where((badge) => badge.name == value)
        .firstOrNull;
  }
}