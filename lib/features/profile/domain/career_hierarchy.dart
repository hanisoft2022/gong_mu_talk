import 'package:equatable/equatable.dart';
import 'lounge_info.dart';
import 'career_track.dart';

/// 계층적 직렬 정보를 담는 클래스
class CareerHierarchy extends Equatable {
  const CareerHierarchy({
    required this.specificCareer,
    this.level1,
    this.level2,
    this.level3,
    this.level4,
  });

  /// 가장 구체적인 직렬 (예: secondary_math_teacher)
  final String specificCareer;

  /// 1단계 (항상 "all" - 전체)
  final String? level1;

  /// 2단계 (예: teacher, admin, police)
  final String? level2;

  /// 3단계 (예: secondary_teacher, elementary_teacher)
  final String? level3;

  /// 4단계 (예: secondary_math_teacher - 가장 세분화된 경우만)
  final String? level4;

  /// 접근 가능한 모든 라운지 정보 반환
  List<LoungeInfo> get accessibleLounges {
    final lounges = <LoungeInfo>[];

    // 1단계: 전체 (항상 포함)
    lounges.add(const LoungeInfo(
      id: 'all',
      name: '전체 공무원',
      emoji: '🏛️',
      shortName: '전체',
      memberCount: 1000000,
      description: '모든 공무원이 참여하는 라운지',
    ));

    // 2단계 추가
    if (level2 != null) {
      lounges.add(_getLoungeInfoForLevel(level2!));
    }

    // 3단계 추가
    if (level3 != null) {
      lounges.add(_getLoungeInfoForLevel(level3!));
    }

    // 4단계 추가
    if (level4 != null) {
      lounges.add(_getLoungeInfoForLevel(level4!));
    }

    return lounges;
  }

  /// 특정 레벨의 라운지 정보 반환
  LoungeInfo _getLoungeInfoForLevel(String levelId) {
    switch (levelId) {
      // 교육 분야
      case 'teacher':
        return const LoungeInfo(
          id: 'teacher',
          name: '교사',
          emoji: '📚',
          shortName: '교사',
          memberCount: 430000,
          description: '모든 교사가 참여하는 라운지',
        );
      case 'elementary_teacher':
        return const LoungeInfo(
          id: 'elementary_teacher',
          name: '초등교사',
          emoji: '🏫',
          shortName: '초등교사',
          memberCount: 180000,
          description: '초등교사 전용 라운지',
        );
      case 'secondary_teacher':
        return const LoungeInfo(
          id: 'secondary_teacher',
          name: '중등교사',
          emoji: '🎓',
          shortName: '중등교사',
          memberCount: 200000,
          description: '중등교사 전용 라운지',
        );
      case 'secondary_math_teacher':
        return const LoungeInfo(
          id: 'secondary_math_teacher',
          name: '중등수학교사',
          emoji: '📐',
          shortName: '중등수학교사',
          memberCount: 30000,
          description: '중등 수학교사 전용 라운지',
        );
      case 'secondary_korean_teacher':
        return const LoungeInfo(
          id: 'secondary_korean_teacher',
          name: '중등국어교사',
          emoji: '📖',
          shortName: '중등국어교사',
          memberCount: 30000,
          description: '중등 국어교사 전용 라운지',
        );
      case 'secondary_english_teacher':
        return const LoungeInfo(
          id: 'secondary_english_teacher',
          name: '중등영어교사',
          emoji: '🌍',
          shortName: '중등영어교사',
          memberCount: 25000,
          description: '중등 영어교사 전용 라운지',
        );
      case 'secondary_science_teacher':
        return const LoungeInfo(
          id: 'secondary_science_teacher',
          name: '중등과학교사',
          emoji: '🔬',
          shortName: '중등과학교사',
          memberCount: 30000,
          description: '중등 과학교사 전용 라운지',
        );
      case 'secondary_social_teacher':
        return const LoungeInfo(
          id: 'secondary_social_teacher',
          name: '중등사회교사',
          emoji: '🌏',
          shortName: '중등사회교사',
          memberCount: 25000,
          description: '중등 사회교사 전용 라운지',
        );
      case 'secondary_arts_teacher':
        return const LoungeInfo(
          id: 'secondary_arts_teacher',
          name: '중등예체능교사',
          emoji: '🎨',
          shortName: '중등예체능교사',
          memberCount: 60000,
          description: '중등 예체능교사 전용 라운지',
        );

      // 행정직
      case 'admin':
        return const LoungeInfo(
          id: 'admin',
          name: '행정직',
          emoji: '🗂️',
          shortName: '행정직',
          memberCount: 280000,
          description: '행정직 공무원 라운지',
        );
      case 'national_admin':
        return const LoungeInfo(
          id: 'national_admin',
          name: '국가행정직',
          emoji: '🏛️',
          shortName: '국가행정직',
          memberCount: 80000,
          description: '국가직 행정공무원 라운지',
        );
      case 'local_admin':
        return const LoungeInfo(
          id: 'local_admin',
          name: '지방행정직',
          emoji: '🏢',
          shortName: '지방행정직',
          memberCount: 150000,
          description: '지방직 행정공무원 라운지',
        );
      case 'admin_9th_national':
        return const LoungeInfo(
          id: 'admin_9th_national',
          name: '9급 국가행정직',
          emoji: '📋',
          shortName: '9급 국가행정직',
          memberCount: 30000,
          description: '9급 국가직 행정공무원 라운지',
        );
      case 'admin_7th_national':
        return const LoungeInfo(
          id: 'admin_7th_national',
          name: '7급 국가행정직',
          emoji: '📊',
          shortName: '7급 국가행정직',
          memberCount: 30000,
          description: '7급 국가직 행정공무원 라운지',
        );
      case 'admin_5th_national':
        return const LoungeInfo(
          id: 'admin_5th_national',
          name: '5급 국가행정직',
          emoji: '💼',
          shortName: '5급 국가행정직',
          memberCount: 20000,
          description: '5급 국가직 행정공무원 라운지',
        );
      case 'admin_9th_local':
        return const LoungeInfo(
          id: 'admin_9th_local',
          name: '9급 지방행정직',
          emoji: '📋',
          shortName: '9급 지방행정직',
          memberCount: 80000,
          description: '9급 지방직 행정공무원 라운지',
        );
      case 'admin_7th_local':
        return const LoungeInfo(
          id: 'admin_7th_local',
          name: '7급 지방행정직',
          emoji: '📊',
          shortName: '7급 지방행정직',
          memberCount: 50000,
          description: '7급 지방직 행정공무원 라운지',
        );
      case 'admin_5th_local':
        return const LoungeInfo(
          id: 'admin_5th_local',
          name: '5급 지방행정직',
          emoji: '💼',
          shortName: '5급 지방행정직',
          memberCount: 20000,
          description: '5급 지방직 행정공무원 라운지',
        );

      // 치안/안전
      case 'police':
        return const LoungeInfo(
          id: 'police',
          name: '경찰관',
          emoji: '👮‍♂️',
          shortName: '경찰관',
          memberCount: 120000,
          description: '경찰관 전용 라운지',
        );
      case 'firefighter':
        return const LoungeInfo(
          id: 'firefighter',
          name: '소방관',
          emoji: '👨‍🚒',
          shortName: '소방관',
          memberCount: 50000,
          description: '소방관 전용 라운지',
        );
      case 'coast_guard':
        return const LoungeInfo(
          id: 'coast_guard',
          name: '해양경찰',
          emoji: '🌊',
          shortName: '해양경찰',
          memberCount: 10000,
          description: '해양경찰 전용 라운지',
        );

      // 군인
      case 'military':
        return const LoungeInfo(
          id: 'military',
          name: '군인',
          emoji: '🎖️',
          shortName: '군인',
          memberCount: 80000,
          description: '군인 전용 라운지',
        );
      case 'army':
        return const LoungeInfo(
          id: 'army',
          name: '육군',
          emoji: '🪖',
          shortName: '육군',
          memberCount: 50000,
          description: '육군 전용 라운지',
        );
      case 'navy':
        return const LoungeInfo(
          id: 'navy',
          name: '해군',
          emoji: '⚓',
          shortName: '해군',
          memberCount: 15000,
          description: '해군 전용 라운지',
        );
      case 'air_force':
        return const LoungeInfo(
          id: 'air_force',
          name: '공군',
          emoji: '✈️',
          shortName: '공군',
          memberCount: 15000,
          description: '공군 전용 라운지',
        );

      // 기타
      case 'postal_service':
        return const LoungeInfo(
          id: 'postal_service',
          name: '우정직',
          emoji: '📮',
          shortName: '우정직',
          memberCount: 20000,
          description: '우정직 공무원 라운지',
        );
      case 'legal_correction':
        return const LoungeInfo(
          id: 'legal_correction',
          name: '법무/교정직',
          emoji: '⚖️',
          shortName: '법무/교정직',
          memberCount: 10000,
          description: '법무/교정직 공무원 라운지',
        );
      case 'security_protection':
        return const LoungeInfo(
          id: 'security_protection',
          name: '교정/보안직',
          emoji: '🔒',
          shortName: '교정/보안직',
          memberCount: 15000,
          description: '교정/보안직 공무원 라운지',
        );
      case 'diplomatic_international':
        return const LoungeInfo(
          id: 'diplomatic_international',
          name: '외교/국제직',
          emoji: '🌍',
          shortName: '외교/국제직',
          memberCount: 4000,
          description: '외교/국제직 공무원 라운지',
        );
      case 'independent_agencies':
        return const LoungeInfo(
          id: 'independent_agencies',
          name: '독립기관',
          emoji: '🏛️',
          shortName: '독립기관',
          memberCount: 5000,
          description: '독립기관 공무원 라운지',
        );

      default:
        return LoungeInfo(
          id: levelId,
          name: levelId,
          emoji: '❓',
          shortName: levelId,
          memberCount: 0,
          description: '알 수 없는 직렬',
        );
    }
  }

  /// 기존 CareerTrack enum과의 호환성을 위한 변환
  CareerTrack get legacyCareerTrack {
    switch (level2) {
      case 'teacher':
        return CareerTrack.teacher;
      case 'admin':
        return CareerTrack.publicAdministration;
      case 'police':
        return CareerTrack.police;
      case 'firefighter':
        return CareerTrack.firefighter;
      case 'legal_correction':
        return CareerTrack.customs; // 임시 매핑
      default:
        return CareerTrack.none;
    }
  }

  /// 특정 직렬로부터 CareerHierarchy 생성
  factory CareerHierarchy.fromSpecificCareer(String specificCareer) {
    switch (specificCareer) {
      // 초등교사
      case 'elementary_teacher':
        return const CareerHierarchy(
          specificCareer: 'elementary_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'elementary_teacher',
        );

      // 중등교사들
      case 'secondary_math_teacher':
        return const CareerHierarchy(
          specificCareer: 'secondary_math_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'secondary_teacher',
          level4: 'secondary_math_teacher',
        );
      case 'secondary_korean_teacher':
        return const CareerHierarchy(
          specificCareer: 'secondary_korean_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'secondary_teacher',
          level4: 'secondary_korean_teacher',
        );
      case 'secondary_english_teacher':
        return const CareerHierarchy(
          specificCareer: 'secondary_english_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'secondary_teacher',
          level4: 'secondary_english_teacher',
        );
      case 'secondary_science_teacher':
        return const CareerHierarchy(
          specificCareer: 'secondary_science_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'secondary_teacher',
          level4: 'secondary_science_teacher',
        );
      case 'secondary_social_teacher':
        return const CareerHierarchy(
          specificCareer: 'secondary_social_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'secondary_teacher',
          level4: 'secondary_social_teacher',
        );
      case 'secondary_arts_teacher':
        return const CareerHierarchy(
          specificCareer: 'secondary_arts_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'secondary_teacher',
          level4: 'secondary_arts_teacher',
        );

      // 행정직들
      case 'admin_9th_national':
        return const CareerHierarchy(
          specificCareer: 'admin_9th_national',
          level1: 'all',
          level2: 'admin',
          level3: 'national_admin',
          level4: 'admin_9th_national',
        );
      case 'admin_7th_national':
        return const CareerHierarchy(
          specificCareer: 'admin_7th_national',
          level1: 'all',
          level2: 'admin',
          level3: 'national_admin',
          level4: 'admin_7th_national',
        );
      case 'admin_5th_national':
        return const CareerHierarchy(
          specificCareer: 'admin_5th_national',
          level1: 'all',
          level2: 'admin',
          level3: 'national_admin',
          level4: 'admin_5th_national',
        );
      case 'admin_9th_local':
        return const CareerHierarchy(
          specificCareer: 'admin_9th_local',
          level1: 'all',
          level2: 'admin',
          level3: 'local_admin',
          level4: 'admin_9th_local',
        );
      case 'admin_7th_local':
        return const CareerHierarchy(
          specificCareer: 'admin_7th_local',
          level1: 'all',
          level2: 'admin',
          level3: 'local_admin',
          level4: 'admin_7th_local',
        );
      case 'admin_5th_local':
        return const CareerHierarchy(
          specificCareer: 'admin_5th_local',
          level1: 'all',
          level2: 'admin',
          level3: 'local_admin',
          level4: 'admin_5th_local',
        );

      // 치안/안전 (2단계)
      case 'police':
        return const CareerHierarchy(
          specificCareer: 'police',
          level1: 'all',
          level2: 'police',
        );
      case 'firefighter':
        return const CareerHierarchy(
          specificCareer: 'firefighter',
          level1: 'all',
          level2: 'firefighter',
        );
      case 'coast_guard':
        return const CareerHierarchy(
          specificCareer: 'coast_guard',
          level1: 'all',
          level2: 'coast_guard',
        );

      // 군인 (3단계)
      case 'army':
        return const CareerHierarchy(
          specificCareer: 'army',
          level1: 'all',
          level2: 'military',
          level3: 'army',
        );
      case 'navy':
        return const CareerHierarchy(
          specificCareer: 'navy',
          level1: 'all',
          level2: 'military',
          level3: 'navy',
        );
      case 'air_force':
        return const CareerHierarchy(
          specificCareer: 'air_force',
          level1: 'all',
          level2: 'military',
          level3: 'air_force',
        );

      // 기타 (2단계)
      case 'postal_service':
      case 'legal_correction':
      case 'security_protection':
      case 'diplomatic_international':
      case 'independent_agencies':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: specificCareer,
        );

      default:
        return const CareerHierarchy(
          specificCareer: 'none',
          level1: 'all',
        );
    }
  }

  /// Firestore 저장용 Map 변환
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'specificCareer': specificCareer,
      'level1': level1,
      'level2': level2,
      'level3': level3,
      'level4': level4,
    };
  }

  /// Map에서 CareerHierarchy 생성
  static CareerHierarchy fromMap(Map<String, Object?> map) {
    return CareerHierarchy(
      specificCareer: map['specificCareer'] as String? ?? 'none',
      level1: map['level1'] as String? ?? 'all',
      level2: map['level2'] as String?,
      level3: map['level3'] as String?,
      level4: map['level4'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    specificCareer,
    level1,
    level2,
    level3,
    level4,
  ];
}