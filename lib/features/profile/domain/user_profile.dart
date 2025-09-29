import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../matching/domain/entities/match_preferences.dart';
import 'career_track.dart';

enum UserRole { member, moderator, admin }

enum PremiumTier { none, supporter, premium }

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.nickname,
    required this.handle,
    required this.serial,
    required this.department,
    required this.region,
    required this.role,
    required this.jobTitle,
    required this.yearsOfService,
    required this.createdAt,
    this.updatedAt,
    this.blockedUntil,
    this.supporterLevel = 0,
    this.premiumTier = PremiumTier.none,
    this.points = 0,
    this.level = 1,
    this.badges = const <String>[],
    this.careerTrack = CareerTrack.none,
    this.matchPreferences = const MatchPreferences(),
    this.excludedSerials = const <String>{},
    this.excludedDepartments = const <String>{},
    this.excludedRegions = const <String>{},
    this.nicknameChangeCount = 0,
    this.nicknameLastChangedAt,
    this.nicknameResetAt,
    this.extraNicknameTickets = 0,
    this.interests = const <String>[],
    this.bio,
    this.photoUrl,
    this.isAnonymousDefault = true,
    this.hasUnreadModerationNotice = false,
    this.moderationStrike = 0,
    this.isDeleted = false,
    this.lastLoginAt,
    this.followerCount = 0,
    this.followingCount = 0,
    this.notificationsEnabled = true,
    this.supporterBadgeVisible = true,
    this.serialVisible = true,
    this.governmentEmail,
    this.governmentEmailVerifiedAt,
  });

  final String uid;
  final String nickname;
  final String handle;
  final String serial;
  final String department;
  final String region;
  final UserRole role;
  final String jobTitle;
  final int yearsOfService;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? blockedUntil;
  final int supporterLevel;
  final PremiumTier premiumTier;
  final int points;
  final int level;
  final List<String> badges;
  final CareerTrack careerTrack;
  final MatchPreferences matchPreferences;
  final Set<String> excludedSerials;
  final Set<String> excludedDepartments;
  final Set<String> excludedRegions;
  final int nicknameChangeCount;
  final DateTime? nicknameLastChangedAt;
  final DateTime? nicknameResetAt;
  final int extraNicknameTickets;
  final List<String> interests;
  final String? bio;
  final bool isAnonymousDefault;
  final bool hasUnreadModerationNotice;
  final int moderationStrike;
  final bool isDeleted;
  final DateTime? lastLoginAt;
  final int followerCount;
  final int followingCount;
  final bool notificationsEnabled;
  final bool supporterBadgeVisible;
  final bool serialVisible;
  final String? governmentEmail;
  final DateTime? governmentEmailVerifiedAt;

  bool get isBlocked =>
      blockedUntil != null && blockedUntil!.isAfter(DateTime.now());

  bool get isPremium => premiumTier != PremiumTier.none;

  bool get hasNicknameTickets => extraNicknameTickets > 0;

  bool get canChangeNickname {
    final DateTime now = DateTime.now();
    final DateTime? resetAnchor = nicknameResetAt;
    if (resetAnchor == null ||
        resetAnchor.year != now.year ||
        resetAnchor.month != now.month) {
      return true;
    }
    return nicknameChangeCount < 1;
  }

  bool get isGovernmentEmailVerified => governmentEmail != null && governmentEmailVerifiedAt != null;

  UserProfile copyWith({
    String? nickname,
    String? handle,
    String? serial,
    String? department,
    String? region,
    UserRole? role,
    String? jobTitle,
    int? yearsOfService,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? blockedUntil,
    int? supporterLevel,
    PremiumTier? premiumTier,
    int? points,
    int? level,
    List<String>? badges,
    CareerTrack? careerTrack,
    MatchPreferences? matchPreferences,
    Set<String>? excludedSerials,
    Set<String>? excludedDepartments,
    Set<String>? excludedRegions,
    int? nicknameChangeCount,
    DateTime? nicknameLastChangedAt,
    DateTime? nicknameResetAt,
    int? extraNicknameTickets,
    List<String>? interests,
    String? bio,
    bool? isAnonymousDefault,
    bool? hasUnreadModerationNotice,
    int? moderationStrike,
    bool? isDeleted,
    DateTime? lastLoginAt,
    int? followerCount,
    int? followingCount,
    bool? notificationsEnabled,
    bool? supporterBadgeVisible,
    bool? serialVisible,
    String? governmentEmail,
    DateTime? governmentEmailVerifiedAt,
  }) {
    return UserProfile(
      uid: uid,
      nickname: nickname ?? this.nickname,
      handle: handle ?? this.handle,
      serial: serial ?? this.serial,
      department: department ?? this.department,
      region: region ?? this.region,
      role: role ?? this.role,
      jobTitle: jobTitle ?? this.jobTitle,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      supporterLevel: supporterLevel ?? this.supporterLevel,
      premiumTier: premiumTier ?? this.premiumTier,
      points: points ?? this.points,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      careerTrack: careerTrack ?? this.careerTrack,
      matchPreferences: matchPreferences ?? this.matchPreferences,
      excludedSerials: excludedSerials ?? this.excludedSerials,
      excludedDepartments: excludedDepartments ?? this.excludedDepartments,
      excludedRegions: excludedRegions ?? this.excludedRegions,
      nicknameChangeCount: nicknameChangeCount ?? this.nicknameChangeCount,
      nicknameLastChangedAt:
          nicknameLastChangedAt ?? this.nicknameLastChangedAt,
      nicknameResetAt: nicknameResetAt ?? this.nicknameResetAt,
      extraNicknameTickets: extraNicknameTickets ?? this.extraNicknameTickets,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      isAnonymousDefault: isAnonymousDefault ?? this.isAnonymousDefault,
      hasUnreadModerationNotice:
          hasUnreadModerationNotice ?? this.hasUnreadModerationNotice,
      moderationStrike: moderationStrike ?? this.moderationStrike,
      isDeleted: isDeleted ?? this.isDeleted,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      supporterBadgeVisible:
          supporterBadgeVisible ?? this.supporterBadgeVisible,
      serialVisible: serialVisible ?? this.serialVisible,
      governmentEmail: governmentEmail ?? this.governmentEmail,
      governmentEmailVerifiedAt: governmentEmailVerifiedAt ?? this.governmentEmailVerifiedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'nickname': nickname,
      'handle': handle,
      'serial': serial,
      'department': department,
      'region': region,
      'role': role.name,
      'jobTitle': jobTitle,
      'yearsOfService': yearsOfService,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'blockedUntil': blockedUntil != null
          ? Timestamp.fromDate(blockedUntil!)
          : null,
      'supporterLevel': supporterLevel,
      'premiumTier': premiumTier.name,
      'points': points,
      'level': level,
      'badges': badges,
      'careerTrack': careerTrack.name,
      'matchPreferences': matchPreferences.toMap(),
      'excludedSerials': excludedSerials.toList(growable: false),
      'excludedDepartments': excludedDepartments.toList(growable: false),
      'excludedRegions': excludedRegions.toList(growable: false),
      'nicknameChangeCount': nicknameChangeCount,
      'nicknameLastChangedAt': nicknameLastChangedAt != null
          ? Timestamp.fromDate(nicknameLastChangedAt!)
          : null,
      'nicknameResetAt': nicknameResetAt != null
          ? Timestamp.fromDate(nicknameResetAt!)
          : null,
      'extraNicknameTickets': extraNicknameTickets,
      'interests': interests,
      'bio': bio,
      'isAnonymousDefault': isAnonymousDefault,
      'hasUnreadModerationNotice': hasUnreadModerationNotice,
      'moderationStrike': moderationStrike,
      'isDeleted': isDeleted,
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'notificationsEnabled': notificationsEnabled,
      'supporterBadgeVisible': supporterBadgeVisible,
      'serialVisible': serialVisible,
      'governmentEmail': governmentEmail,
      'governmentEmailVerifiedAt': governmentEmailVerifiedAt != null
          ? Timestamp.fromDate(governmentEmailVerifiedAt!)
          : null,
    };
  }

  static UserProfile fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snapshot,
  ) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('User profile document ${snapshot.id} has no data');
    }

    return fromMap(snapshot.id, data);
  }

  static UserProfile fromMap(String uid, Map<String, Object?> data) {
    return UserProfile(
      uid: uid,
      nickname: (data['nickname'] as String?) ?? '공무원',
      handle: (data['handle'] as String?) ?? uid,
      serial: (data['serial'] as String?) ?? 'unknown',
      department: (data['department'] as String?) ?? 'unknown',
      region: (data['region'] as String?) ?? 'unknown',
      role: _parseRole(data['role']),
      jobTitle: (data['jobTitle'] as String?) ?? '직무 정보 없음',
      yearsOfService: (data['yearsOfService'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      blockedUntil: _parseTimestamp(data['blockedUntil']),
      supporterLevel: (data['supporterLevel'] as num?)?.toInt() ?? 0,
      premiumTier: _parsePremium(data['premiumTier']),
      points: (data['points'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      badges: _parseStringList(data['badges']),
      careerTrack: _parseCareerTrack(data['careerTrack']),
      matchPreferences: MatchPreferences.fromMap(
        (data['matchPreferences'] as Map<String, Object?>?) ??
            (data['matchingSurvey'] as Map<String, Object?>?),
      ),
      excludedSerials: _parseStringSet(data['excludedSerials']),
      excludedDepartments: _parseStringSet(data['excludedDepartments']),
      excludedRegions: _parseStringSet(data['excludedRegions']),
      nicknameChangeCount: (data['nicknameChangeCount'] as num?)?.toInt() ?? 0,
      nicknameLastChangedAt: _parseTimestamp(data['nicknameLastChangedAt']),
      nicknameResetAt: _parseTimestamp(data['nicknameResetAt']),
      extraNicknameTickets:
          (data['extraNicknameTickets'] as num?)?.toInt() ?? 0,
      interests: _parseStringList(data['interests']),
      bio: data['bio'] as String?,
      isAnonymousDefault: data['isAnonymousDefault'] as bool? ?? true,
      hasUnreadModerationNotice:
          data['hasUnreadModerationNotice'] as bool? ?? false,
      moderationStrike: (data['moderationStrike'] as num?)?.toInt() ?? 0,
      isDeleted: data['isDeleted'] as bool? ?? false,
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      supporterBadgeVisible: data['supporterBadgeVisible'] as bool? ?? true,
      serialVisible: data['serialVisible'] as bool? ?? true,
      governmentEmail: data['governmentEmail'] as String?,
      governmentEmailVerifiedAt: _parseTimestamp(data['governmentEmailVerifiedAt']),
    );
  }

  static UserRole _parseRole(Object? raw) {
    if (raw is String) {
      return UserRole.values.firstWhere(
        (UserRole element) => element.name == raw,
        orElse: () => UserRole.member,
      );
    }
    return UserRole.member;
  }

  static PremiumTier _parsePremium(Object? raw) {
    if (raw is String) {
      return PremiumTier.values.firstWhere(
        (PremiumTier element) => element.name == raw,
        orElse: () => PremiumTier.none,
      );
    }
    return PremiumTier.none;
  }

  static CareerTrack _parseCareerTrack(Object? raw) {
    if (raw is String) {
      return CareerTrack.values.firstWhere(
        (CareerTrack element) => element.name == raw,
        orElse: () => CareerTrack.none,
      );
    }
    return CareerTrack.none;
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is Iterable) {
      return raw.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  static Set<String> _parseStringSet(Object? raw) {
    if (raw is Iterable) {
      return raw.whereType<String>().toSet();
    }
    return const <String>{};
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
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    uid,
    nickname,
    handle,
    serial,
    department,
    region,
    role,
    jobTitle,
    yearsOfService,
    photoUrl,
    createdAt,
    updatedAt,
    blockedUntil,
    supporterLevel,
    premiumTier,
    points,
    level,
    badges,
    careerTrack,
    matchPreferences,
    excludedSerials,
    excludedDepartments,
    excludedRegions,
    nicknameChangeCount,
    nicknameLastChangedAt,
    nicknameResetAt,
    extraNicknameTickets,
    interests,
    bio,
    isAnonymousDefault,
    hasUnreadModerationNotice,
    moderationStrike,
    isDeleted,
    lastLoginAt,
    followerCount,
    followingCount,
    notificationsEnabled,
    supporterBadgeVisible,
    serialVisible,
    governmentEmail,
    governmentEmailVerifiedAt,
  ];
}
