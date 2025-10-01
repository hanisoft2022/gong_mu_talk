import '../../../profile/domain/career_hierarchy.dart';
import '../../../profile/domain/lounge_info.dart';
import '../models/lounge.dart';

/// 라운지 접근 권한 관리 서비스
class LoungeAccessService {
  /// 사용자의 직렬 계층 정보를 바탕으로 접근 가능한 라운지 목록 반환
  static List<Lounge> getAccessibleLounges(CareerHierarchy careerHierarchy) {
    final accessibleIds = _getAccessibleLoungeIds(careerHierarchy);

    return LoungeDefinitions.defaultLounges
        .where((lounge) => accessibleIds.contains(lounge.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// 사용자의 직렬 계층 정보를 바탕으로 접근 가능한 라운지 ID 목록 반환
  static List<String> _getAccessibleLoungeIds(CareerHierarchy careerHierarchy) {
    final accessibleIds = <String>['all']; // 전체 라운지는 항상 접근 가능

    // level2가 있으면 추가 (teacher, admin 등)
    if (careerHierarchy.level2 != null) {
      accessibleIds.add(careerHierarchy.level2!);
    }

    // level3가 있으면 추가 (elementary_teacher, secondary_teacher 등)
    if (careerHierarchy.level3 != null) {
      accessibleIds.add(careerHierarchy.level3!);
    }

    // level4가 있으면 추가 (secondary_math_teacher 등)
    if (careerHierarchy.level4 != null) {
      accessibleIds.add(careerHierarchy.level4!);
    }

    return accessibleIds;
  }

  /// 특정 라운지에 접근 가능한지 확인
  static bool canAccessLounge(String loungeId, CareerHierarchy careerHierarchy) {
    final accessibleIds = _getAccessibleLoungeIds(careerHierarchy);
    return accessibleIds.contains(loungeId);
  }

  /// 사용자의 가장 구체적인 라운지 ID 반환 (기본 라운지)
  static String getDefaultLoungeId(CareerHierarchy careerHierarchy) {
    // 가장 구체적인 레벨부터 확인
    if (careerHierarchy.level4 != null) {
      return careerHierarchy.level4!;
    }
    if (careerHierarchy.level3 != null) {
      return careerHierarchy.level3!;
    }
    if (careerHierarchy.level2 != null) {
      return careerHierarchy.level2!;
    }
    return 'all';
  }

  /// CareerHierarchy를 LoungeInfo 목록으로 변환 (기존 호환성)
  static List<LoungeInfo> convertToLoungeInfos(CareerHierarchy careerHierarchy) {
    final accessibleLounges = getAccessibleLounges(careerHierarchy);

    return accessibleLounges.map((lounge) => LoungeInfo(
      id: lounge.id,
      name: lounge.name,
      emoji: lounge.emoji,
      shortName: lounge.shortName ?? lounge.name,
      memberCount: lounge.memberCount,
      description: lounge.description,
    )).toList();
  }

  /// Lounge 정보에서 접근 가능한 직렬 목록 가져오기 (UI용)
  static List<String> getRequiredCareerIds(String loungeId) {
    final lounge = LoungeDefinitions.defaultLounges.firstWhere(
      (l) => l.id == loungeId,
      orElse: () => LoungeDefinitions.defaultLounges.first,
    );
    return lounge.requiredCareerIds;
  }

  /// 직렬별 라운지 맵핑 정의 - 급여명세서 키워드와 라운지 연결
  static Map<String, List<String>> get careerToLoungeMapping => {
    // ================================
    // 교육공무원 (Education Officials)
    // ================================

    // 초등교사 (Elementary Teacher)
    'elementary_teacher': ['all', 'teacher', 'elementary_teacher'],

    // 중등교사 - 교과별 (Secondary Teachers by Subject)
    'secondary_math_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_math_teacher'],
    'secondary_korean_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_korean_teacher'],
    'secondary_english_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_english_teacher'],
    'secondary_science_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_science_teacher'],
    'secondary_social_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_social_teacher'],
    'secondary_arts_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_arts_teacher'],

    // 유치원 교사 (Kindergarten Teacher)
    'kindergarten_teacher': ['all', 'teacher', 'kindergarten_teacher'],

    // 특수교육 교사 (Special Education Teacher)
    'special_education_teacher': ['all', 'teacher', 'special_education_teacher'],

    // 비교과 교사들 (Non-Subject Teachers) - 통합 라운지
    'counselor_teacher': ['all', 'teacher', 'non_subject_teacher'],
    'health_teacher': ['all', 'teacher', 'non_subject_teacher'],
    'librarian_teacher': ['all', 'teacher', 'non_subject_teacher'],
    'nutrition_teacher': ['all', 'teacher', 'non_subject_teacher'],

    // ================================
    // 일반행정직 (General Administrative)
    // ================================

    // 국가직 (National)
    'admin_9th_national': ['all', 'admin', 'national_admin', 'admin_9th_national'],
    'admin_7th_national': ['all', 'admin', 'national_admin', 'admin_7th_national'],
    'admin_5th_national': ['all', 'admin', 'national_admin', 'admin_5th_national'],

    // 지방직 (Local)
    'admin_9th_local': ['all', 'admin', 'local_admin', 'admin_9th_local'],
    'admin_7th_local': ['all', 'admin', 'local_admin', 'admin_7th_local'],
    'admin_5th_local': ['all', 'admin', 'local_admin', 'admin_5th_local'],

    // 세무·관세직 (Tax & Customs) - 통합 라운지
    'tax_officer': ['all', 'admin', 'tax_customs'],
    'customs_officer': ['all', 'admin', 'tax_customs'],

    // ================================
    // 전문행정직 (Specialized Administrative)
    // ================================

    'job_counselor': ['all', 'admin', 'specialized_admin'],
    'statistics_officer': ['all', 'admin', 'specialized_admin'],
    'librarian': ['all', 'admin', 'specialized_admin'],
    'auditor': ['all', 'admin', 'specialized_admin'],
    'security_officer': ['all', 'admin', 'specialized_admin'],

    // ================================
    // 보건복지직 (Health & Welfare)
    // ================================

    'public_health_officer': ['all', 'health_welfare'],
    'medical_technician': ['all', 'health_welfare'],
    'nurse': ['all', 'health_welfare'],
    'medical_officer': ['all', 'health_welfare'],
    'pharmacist': ['all', 'health_welfare'],
    'food_sanitation': ['all', 'health_welfare'],
    'social_worker': ['all', 'health_welfare'],

    // ================================
    // 공안직 (Public Security)
    // ================================

    'correction_officer': ['all', 'public_security'],
    'probation_officer': ['all', 'public_security'],
    'prosecution_officer': ['all', 'public_security'],
    'drug_investigation_officer': ['all', 'public_security'],
    'immigration_officer': ['all', 'public_security'],
    'railroad_police': ['all', 'public_security'],
    'security_guard': ['all', 'public_security'],

    // ================================
    // 치안/안전 (Public Safety)
    // ================================

    'police': ['all', 'police'],
    'firefighter': ['all', 'firefighter'],
    'coast_guard': ['all', 'coast_guard'],

    // ================================
    // 군인 (Military)
    // ================================

    'army': ['all', 'military', 'army'],
    'navy': ['all', 'military', 'navy'],
    'air_force': ['all', 'military', 'air_force'],
    'military_civilian': ['all', 'military', 'military_civilian'],

    // ================================
    // 기술직 (Technical Tracks)
    // ================================

    // 공업직 (Industrial/Engineering) - 통합 라운지
    'mechanical_engineer': ['all', 'technical', 'industrial_engineer'],
    'electrical_engineer': ['all', 'technical', 'industrial_engineer'],
    'electronics_engineer': ['all', 'technical', 'industrial_engineer'],
    'chemical_engineer': ['all', 'technical', 'industrial_engineer'],
    'shipbuilding_engineer': ['all', 'technical', 'industrial_engineer'],
    'nuclear_engineer': ['all', 'technical', 'industrial_engineer'],
    'metal_engineer': ['all', 'technical', 'industrial_engineer'],
    'textile_engineer': ['all', 'technical', 'industrial_engineer'],

    // 시설환경직 (Facilities & Environment) - 통합 라운지
    'civil_engineer': ['all', 'technical', 'facilities_environment'],
    'architect': ['all', 'technical', 'facilities_environment'],
    'landscape_architect': ['all', 'technical', 'facilities_environment'],
    'traffic_engineer': ['all', 'technical', 'facilities_environment'],
    'cadastral_officer': ['all', 'technical', 'facilities_environment'],
    'designer': ['all', 'technical', 'facilities_environment'],
    'environmental_officer': ['all', 'technical', 'facilities_environment'],

    // 농림수산직 (Agriculture, Forestry, Fisheries) - 통합 라운지
    'agriculture_officer': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'plant_quarantine': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'livestock_officer': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'forestry_officer': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'marine_officer': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'fisheries_officer': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'ship_officer': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'veterinarian': ['all', 'technical', 'agriculture_forestry_fisheries'],
    'agricultural_extension': ['all', 'technical', 'agriculture_forestry_fisheries'],

    // IT통신직 (IT & Communications) - 통합 라운지
    'computer_officer': ['all', 'technical', 'it_communications'],
    'broadcasting_communication': ['all', 'technical', 'it_communications'],

    // 관리운영직 (Management & Operations) - 통합 라운지
    'facility_management': ['all', 'technical', 'management_operations'],
    'sanitation_worker': ['all', 'technical', 'management_operations'],
    'cook': ['all', 'technical', 'management_operations'],

    // ================================
    // 기타 직렬 (Others)
    // ================================

    'postal_service': ['all', 'postal_service'],
    'researcher': ['all', 'researcher'],

    // ================================
    // Fallback - 일반 직렬
    // ================================

    'teacher': ['all', 'teacher'],
    'admin': ['all', 'admin'],
  };

  /// 급여명세서 키워드에서 직접 라운지 접근 목록 생성
  static List<String> getLoungeIdsFromCareer(String careerTrackId) {
    return careerToLoungeMapping[careerTrackId] ?? ['all'];
  }

  /// 라운지 계층 구조 검증 - 부모 라운지 접근 권한이 있는지 확인
  static bool hasParentAccess(String loungeId, List<String> accessibleLoungeIds) {
    final lounge = LoungeDefinitions.defaultLounges
        .firstWhere((l) => l.id == loungeId, orElse: () => const Lounge(
          id: '',
          name: '',
          emoji: '',
          type: LoungeType.specific,
          accessType: LoungeAccessType.careerOnly,
          requiredCareerIds: [],
        ));

    if (lounge.parentLoungeId == null) {
      return true; // 최상위 라운지
    }

    return accessibleLoungeIds.contains(lounge.parentLoungeId);
  }

  /// 라운지 멤버십 정보 업데이트 (Future enhancement)
  static Future<void> updateLoungeMembership(
    String userId,
    List<String> newAccessibleLoungeIds,
  ) async {
    // TODO: Firestore에 사용자의 라운지 멤버십 정보 저장
    // 향후 실시간 멤버 수 업데이트, 라운지별 알림 설정 등에 활용
  }
}