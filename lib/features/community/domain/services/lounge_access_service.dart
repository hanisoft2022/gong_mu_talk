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

  /// 직렬별 라운지 맵핑 정의 - 급여명세서 키워드와 라운지 연결
  static Map<String, List<String>> get careerToLoungeMapping => {
    // 교육 분야
    'elementary_teacher': ['all', 'teacher', 'elementary_teacher'],
    'secondary_math_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_math_teacher'],
    'secondary_korean_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_korean_teacher'],
    'secondary_english_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_english_teacher'],
    'secondary_science_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_science_teacher'],
    'secondary_social_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_social_teacher'],
    'secondary_arts_teacher': ['all', 'teacher', 'secondary_teacher', 'secondary_arts_teacher'],
    'counselor_teacher': ['all', 'teacher'],
    'health_teacher': ['all', 'teacher'],
    'librarian_teacher': ['all', 'teacher'],
    'nutrition_teacher': ['all', 'teacher'],

    // 행정직
    'admin_9th_national': ['all', 'admin', 'national_admin', 'admin_9th_national'],
    'admin_7th_national': ['all', 'admin', 'national_admin', 'admin_7th_national'],
    'admin_5th_national': ['all', 'admin', 'national_admin', 'admin_5th_national'],
    'admin_9th_local': ['all', 'admin', 'local_admin', 'admin_9th_local'],
    'admin_7th_local': ['all', 'admin', 'local_admin', 'admin_7th_local'],
    'admin_5th_local': ['all', 'admin', 'local_admin', 'admin_5th_local'],

    // 치안/안전
    'police': ['all', 'police'],
    'firefighter': ['all', 'firefighter'],
    'coast_guard': ['all', 'coast_guard'],

    // 군인
    'army': ['all', 'military', 'army'],
    'navy': ['all', 'military', 'navy'],
    'air_force': ['all', 'military', 'air_force'],

    // 기타
    'postal_service': ['all', 'postal_service'],
    'legal_correction': ['all', 'legal_correction'],
    'security_protection': ['all', 'security_protection'],
    'diplomatic_international': ['all', 'diplomatic_international'],
    'independent_agencies': ['all', 'independent_agencies'],

    // 일반적인 분류 (fallback)
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