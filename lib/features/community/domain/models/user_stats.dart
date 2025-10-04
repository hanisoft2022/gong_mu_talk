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
    final progress =
        (points - currentLevelPoints) / (nextLevelPoints - currentLevelPoints);
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
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
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
