import 'package:equatable/equatable.dart';
import 'lounge_info.dart';
import 'career_track.dart';
import '../../community/domain/services/lounge_access_service.dart';

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
  /// LoungeAccessService를 통해 중앙 집중식으로 관리
  List<LoungeInfo> get accessibleLounges {
    return LoungeAccessService.convertToLoungeInfos(this);
  }

  /// 기존 CareerTrack enum과의 호환성을 위한 변환
  CareerTrack get legacyCareerTrack {
    switch (level2) {
      case 'teacher':
        return CareerTrack.teacher;
      case 'education_admin':
        return CareerTrack.educationAdmin;
      case 'admin':
        return CareerTrack.publicAdministration;
      case 'police':
        return CareerTrack.police;
      case 'firefighter':
        return CareerTrack.firefighter;
      case 'legal_correction':
      case 'legal_profession':
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
      // 교육행정직 (Education Administrative)
      // ================================

      // 국가 교육행정직
      case 'education_admin_9th_national':
        return const CareerHierarchy(
          specificCareer: 'education_admin_9th_national',
          level1: 'all',
          level2: 'education_admin',
          level3: 'national_education_admin',
          level4: 'education_admin_9th_national',
        );
      case 'education_admin_7th_national':
        return const CareerHierarchy(
          specificCareer: 'education_admin_7th_national',
          level1: 'all',
          level2: 'education_admin',
          level3: 'national_education_admin',
          level4: 'education_admin_7th_national',
        );

      // 지방 교육행정직
      case 'education_admin_9th_local':
        return const CareerHierarchy(
          specificCareer: 'education_admin_9th_local',
          level1: 'all',
          level2: 'education_admin',
          level3: 'local_education_admin',
          level4: 'education_admin_9th_local',
        );
      case 'education_admin_7th_local':
        return const CareerHierarchy(
          specificCareer: 'education_admin_7th_local',
          level1: 'all',
          level2: 'education_admin',
          level3: 'local_education_admin',
          level4: 'education_admin_7th_local',
        );

      // ================================
      // 법조직 (Legal Profession)
      // ================================

      case 'judge':
      case 'prosecutor':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'legal_profession',
        );

      // ================================
      // 외교직 (Diplomatic Service)
      // ================================

      case 'diplomat_5th':
      case 'diplomat_consular':
      case 'diplomat_3rd':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'diplomat',
        );

      // ================================
      // 문화예술직 (Culture & Arts)
      // ================================

      case 'curator':
      case 'cultural_heritage':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'culture_arts',
        );

      // ================================
      // 과학기술 전문직 (Science & Technology Specialized)
      // ================================

      case 'meteorologist':
      case 'disaster_safety':
      case 'nursing_assistant':
      case 'health_care':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'science_technology_specialized',
        );

      // ================================
      // 독립기관직 (Independent Agencies)
      // ================================

      case 'national_assembly':
      case 'constitutional_court':
      case 'election_commission':
      case 'audit_board':
      case 'human_rights_commission':
        return CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all',
          level2: 'independent_agencies',
        );

      // ================================
      // 프라이버시 보호 직렬 (Privacy Protected - All Lounge Only)
      // 소규모 직렬(1,000명 미만) 또는 보안 민감 직렬
      // ================================

      case 'constitutional_researcher': // 헌법연구관 (~50명)
      case 'security_service': // 경호공무원 (~500명)
      case 'intelligence_service': // 국가정보원 (보안 민감)
      case 'aviation': // 항공직 (~500명)
      case 'broadcasting_stage': // 방송무대직 (~300명)
      case 'driving': // 운전직 (~5,000명, 신원 특정 가능)
        return const CareerHierarchy(
          specificCareer: specificCareer,
          level1: 'all', // 전체 라운지만 접근
        );

      // ================================
      // Fallback / Legacy
      // ================================

      case 'legal_correction':
      case 'security_protection':
      case 'diplomatic_international':
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
