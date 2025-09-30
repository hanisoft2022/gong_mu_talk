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
    lounges.add(
      const LoungeInfo(
        id: 'all',
        name: '전체',
        emoji: '🏛️',
        shortName: '전체',
        memberCount: 1000000,
        description: '모든 공무원이 참여하는 라운지',
      ),
    );

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

      // ================================
      // 교육공무원 (추가 라운지)
      // ================================

      case 'kindergarten_teacher':
        return const LoungeInfo(
          id: 'kindergarten_teacher',
          name: '유치원교사',
          emoji: '👶',
          shortName: '유치원교사',
          memberCount: 5000,
          description: '유치원교사 전용 라운지',
        );
      case 'special_education_teacher':
        return const LoungeInfo(
          id: 'special_education_teacher',
          name: '특수교육교사',
          emoji: '🤝',
          shortName: '특수교육교사',
          memberCount: 4000,
          description: '특수교육교사 전용 라운지',
        );
      case 'non_subject_teacher':
        return const LoungeInfo(
          id: 'non_subject_teacher',
          name: '비교과교사',
          emoji: '💼',
          shortName: '비교과교사',
          memberCount: 15000,
          description: '상담·보건·사서·영양 교사 라운지',
        );

      // ================================
      // 행정직 (추가 라운지)
      // ================================

      case 'tax_customs':
        return const LoungeInfo(
          id: 'tax_customs',
          name: '세무·관세직',
          emoji: '💰',
          shortName: '세무·관세직',
          memberCount: 25000,
          description: '세무직 및 관세직 공무원 라운지',
        );
      case 'specialized_admin':
        return const LoungeInfo(
          id: 'specialized_admin',
          name: '전문행정직',
          emoji: '📋',
          shortName: '전문행정직',
          memberCount: 30000,
          description: '고용노동·통계·사서·감사·방호직 라운지',
        );

      // ================================
      // 보건복지직 (Health & Welfare)
      // ================================

      case 'health_welfare':
        return const LoungeInfo(
          id: 'health_welfare',
          name: '보건복지직',
          emoji: '🏥',
          shortName: '보건복지직',
          memberCount: 80000,
          description: '보건·의료·간호·약무·복지직 라운지',
        );

      // ================================
      // 공안직 (Public Security)
      // ================================

      case 'public_security':
        return const LoungeInfo(
          id: 'public_security',
          name: '공안직',
          emoji: '⚖️',
          shortName: '공안직',
          memberCount: 50000,
          description: '교정·검찰·마약수사·출입국관리직 라운지',
        );

      // ================================
      // 군인 (추가)
      // ================================

      case 'military_civilian':
        return const LoungeInfo(
          id: 'military_civilian',
          name: '군무원',
          emoji: '🎖️',
          shortName: '군무원',
          memberCount: 30000,
          description: '군무원 전용 라운지',
        );

      // ================================
      // 기술직 (Technical Tracks)
      // ================================

      case 'technical':
        return const LoungeInfo(
          id: 'technical',
          name: '기술직',
          emoji: '⚙️',
          shortName: '기술직',
          memberCount: 300000,
          description: '모든 기술직 공무원 라운지',
        );
      case 'industrial_engineer':
        return const LoungeInfo(
          id: 'industrial_engineer',
          name: '공업직',
          emoji: '⚙️',
          shortName: '공업직',
          memberCount: 50000,
          description: '기계·전기·전자·화공직 등 공업 기술직',
        );
      case 'facilities_environment':
        return const LoungeInfo(
          id: 'facilities_environment',
          name: '시설환경직',
          emoji: '🏗️',
          shortName: '시설환경직',
          memberCount: 47000,
          description: '토목·건축·환경직 등 시설환경 기술직',
        );
      case 'agriculture_forestry_fisheries':
        return const LoungeInfo(
          id: 'agriculture_forestry_fisheries',
          name: '농림수산직',
          emoji: '🌾',
          shortName: '농림수산직',
          memberCount: 70000,
          description: '농업·수산·축산·수의직 등',
        );
      case 'it_communications':
        return const LoungeInfo(
          id: 'it_communications',
          name: 'IT통신직',
          emoji: '💻',
          shortName: 'IT통신직',
          memberCount: 20000,
          description: '전산·방송통신직 라운지',
        );
      case 'management_operations':
        return const LoungeInfo(
          id: 'management_operations',
          name: '관리운영직',
          emoji: '🏢',
          shortName: '관리운영직',
          memberCount: 35000,
          description: '시설관리·위생·조리직 라운지',
        );

      // ================================
      // 기타 직렬
      // ================================

      case 'postal_service':
        return const LoungeInfo(
          id: 'postal_service',
          name: '우정직',
          emoji: '📮',
          shortName: '우정직',
          memberCount: 50000,
          description: '우정직 공무원 라운지',
        );
      case 'researcher':
        return const LoungeInfo(
          id: 'researcher',
          name: '연구직',
          emoji: '🔬',
          shortName: '연구직',
          memberCount: 20000,
          description: '연구직 공무원 라운지',
        );

      // ================================
      // Legacy (기존 호환성)
      // ================================

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
      // ================================
      // 교육공무원 (Education Officials)
      // ================================

      // 초등교사
      case 'elementary_teacher':
        return const CareerHierarchy(
          specificCareer: 'elementary_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'elementary_teacher',
        );

      // 중등교사 - 교과별
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

      // 유치원 교사
      case 'kindergarten_teacher':
        return const CareerHierarchy(
          specificCareer: 'kindergarten_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'kindergarten_teacher',
        );

      // 특수교육 교사
      case 'special_education_teacher':
        return const CareerHierarchy(
          specificCareer: 'special_education_teacher',
          level1: 'all',
          level2: 'teacher',
          level3: 'special_education_teacher',
        );

      // 비교과 교사들 (통합 라운지)
      case 'counselor_teacher':
      case 'health_teacher':
      case 'librarian_teacher':
      case 'nutrition_teacher':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'teacher',
          level3: 'non_subject_teacher',
        );

      // ================================
      // 일반행정직 (General Administrative)
      // ================================

      // 국가직
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

      // 지방직
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

      // 세무·관세직 (통합 라운지)
      case 'tax_officer':
      case 'customs_officer':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'admin',
          level3: 'tax_customs',
        );

      // ================================
      // 전문행정직 (Specialized Administrative)
      // ================================

      case 'job_counselor':
      case 'statistics_officer':
      case 'librarian':
      case 'auditor':
      case 'security_officer':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'admin',
          level3: 'specialized_admin',
        );

      // ================================
      // 보건복지직 (Health & Welfare)
      // ================================

      case 'public_health_officer':
      case 'medical_technician':
      case 'nurse':
      case 'medical_officer':
      case 'pharmacist':
      case 'food_sanitation':
      case 'social_worker':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'health_welfare',
        );

      // ================================
      // 공안직 (Public Security)
      // ================================

      case 'correction_officer':
      case 'probation_officer':
      case 'prosecution_officer':
      case 'drug_investigation_officer':
      case 'immigration_officer':
      case 'railroad_police':
      case 'security_guard':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'public_security',
        );

      // ================================
      // 치안/안전 (Public Safety)
      // ================================

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

      // ================================
      // 군인 (Military)
      // ================================

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
      case 'military_civilian':
        return const CareerHierarchy(
          specificCareer: 'military_civilian',
          level1: 'all',
          level2: 'military',
          level3: 'military_civilian',
        );

      // ================================
      // 기술직 (Technical Tracks)
      // ================================

      // 공업직 (Industrial/Engineering) - 통합 라운지
      case 'mechanical_engineer':
      case 'electrical_engineer':
      case 'electronics_engineer':
      case 'chemical_engineer':
      case 'shipbuilding_engineer':
      case 'nuclear_engineer':
      case 'metal_engineer':
      case 'textile_engineer':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'technical',
          level3: 'industrial_engineer',
        );

      // 시설환경직 (Facilities & Environment) - 통합 라운지
      case 'civil_engineer':
      case 'architect':
      case 'landscape_architect':
      case 'traffic_engineer':
      case 'cadastral_officer':
      case 'designer':
      case 'environmental_officer':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'technical',
          level3: 'facilities_environment',
        );

      // 농림수산직 (Agriculture, Forestry, Fisheries) - 통합 라운지
      case 'agriculture_officer':
      case 'plant_quarantine':
      case 'livestock_officer':
      case 'forestry_officer':
      case 'marine_officer':
      case 'fisheries_officer':
      case 'ship_officer':
      case 'veterinarian':
      case 'agricultural_extension':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'technical',
          level3: 'agriculture_forestry_fisheries',
        );

      // IT통신직 (IT & Communications) - 통합 라운지
      case 'computer_officer':
      case 'broadcasting_communication':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'technical',
          level3: 'it_communications',
        );

      // 관리운영직 (Management & Operations) - 통합 라운지
      case 'facility_management':
      case 'sanitation_worker':
      case 'cook':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'technical',
          level3: 'management_operations',
        );

      // ================================
      // 기타 직렬 (Others)
      // ================================

      case 'postal_service':
        return const CareerHierarchy(
          specificCareer: 'postal_service',
          level1: 'all',
          level2: 'postal_service',
        );
      case 'researcher':
        return const CareerHierarchy(
          specificCareer: 'researcher',
          level1: 'all',
          level2: 'researcher',
        );

      // ================================
      // Fallback / Legacy
      // ================================

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
        return const CareerHierarchy(specificCareer: 'none', level1: 'all');
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
  List<Object?> get props => [specificCareer, level1, level2, level3, level4];
}
