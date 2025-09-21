import 'package:equatable/equatable.dart';

import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/user_profile.dart';

enum MatchProfileStage { anonymized, nicknameRevealed, fullProfile }

class MatchProfile extends Equatable {
  const MatchProfile({
    required this.id,
    required this.nickname,
    required this.maskedNickname,
    required this.serial,
    required this.department,
    required this.region,
    required this.jobTitle,
    required this.yearsOfService,
    required this.introduction,
    required this.interests,
    required this.careerTrack,
    required this.badges,
    required this.stage,
    required this.isPremium,
    required this.premiumTier,
    this.photoUrl,
    this.points,
    this.level,
  });

  final String id;
  final String nickname;
  final String maskedNickname;
  final String serial;
  final String department;
  final String region;
  final String jobTitle;
  final int yearsOfService;
  final String introduction;
  final List<String> interests;
  final CareerTrack careerTrack;
  final List<String> badges;
  final MatchProfileStage stage;
  final bool isPremium;
  final PremiumTier premiumTier;
  final String? photoUrl;
  final int? points;
  final int? level;

  MatchProfile copyWith({
    MatchProfileStage? stage,
    bool? isPremium,
    PremiumTier? premiumTier,
    int? points,
    int? level,
  }) {
    return MatchProfile(
      id: id,
      nickname: nickname,
      maskedNickname: maskedNickname,
      serial: serial,
      department: department,
      region: region,
      jobTitle: jobTitle,
      yearsOfService: yearsOfService,
      introduction: introduction,
      interests: interests,
      careerTrack: careerTrack,
      badges: badges,
      stage: stage ?? this.stage,
      isPremium: isPremium ?? this.isPremium,
      premiumTier: premiumTier ?? this.premiumTier,
      photoUrl: photoUrl,
      points: points ?? this.points,
      level: level ?? this.level,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    maskedNickname,
    serial,
    department,
    region,
    jobTitle,
    yearsOfService,
    introduction,
    interests,
    careerTrack,
    badges,
    stage,
    isPremium,
    premiumTier,
    photoUrl,
    points,
    level,
  ];
}
