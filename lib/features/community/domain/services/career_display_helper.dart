/// 직렬 그룹 정보
library;

import '../models/lounge_definitions.dart';

class CareerGroup {
  const CareerGroup({required this.name, required this.careerIds});

  final String name;
  final List<String> careerIds;
}

/// 직렬 ID를 한글 표시명으로 변환하는 헬퍼 클래스
///
/// **Single Source of Truth**: LoungeDefinitions를 사용합니다.
/// 직렬명과 이모지는 LoungeDefinitions에서만 관리되며, 이 클래스는 조회 헬퍼입니다.
class CareerDisplayHelper {
  /// 직렬 ID를 한글 이름으로 변환
  ///
  /// LoungeDefinitions에서 해당 직렬의 name을 찾아 반환합니다.
  static String getCareerDisplayName(String careerId) {
    final lounge = LoungeDefinitions.defaultLounges.firstWhere(
      (l) => l.id == careerId,
      orElse: () => LoungeDefinitions.defaultLounges.first,
    );

    // 매칭되는 라운지를 찾았으면 그 이름 반환, 아니면 careerId 그대로 반환
    return lounge.id == careerId ? lounge.name : careerId;
  }

  /// 직렬 ID를 이모지로 변환
  ///
  /// LoungeDefinitions에서 해당 직렬의 emoji를 찾아 반환합니다.
  static String getCareerEmoji(String careerId) {
    final lounge = LoungeDefinitions.defaultLounges.firstWhere(
      (l) => l.id == careerId,
      orElse: () => LoungeDefinitions.defaultLounges.first,
    );

    // 매칭되는 라운지를 찾았으면 그 이모지 반환, 아니면 기본 이모지 반환
    return lounge.id == careerId ? lounge.emoji : '👤';
  }

  /// 여러 직렬 ID를 간략하게 표시 (최대 3개 + "외 N개")
  static String getCompactCareerList(
    List<String> careerIds, {
    int maxDisplay = 3,
  }) {
    if (careerIds.isEmpty) return '';

    final displayNames = careerIds
        .take(maxDisplay)
        .map(getCareerDisplayName)
        .toList();
    final remaining = careerIds.length - maxDisplay;

    if (remaining > 0) {
      return '${displayNames.join('·')} 외 $remaining개';
    }

    return displayNames.join('·');
  }

  /// 직렬 ID 목록을 그룹으로 분류
  static List<CareerGroup> groupCareers(List<String> careerIds) {
    final groups = <CareerGroup>[];

    // 국가행정직 그룹
    final nationalAdmins = careerIds
        .where(
          (id) =>
              id == 'admin_9th_national' ||
              id == 'admin_7th_national' ||
              id == 'admin_5th_national',
        )
        .toList();
    if (nationalAdmins.isNotEmpty) {
      groups.add(CareerGroup(name: '국가행정직', careerIds: nationalAdmins));
    }

    // 지방행정직 그룹
    final localAdmins = careerIds
        .where(
          (id) =>
              id == 'admin_9th_local' ||
              id == 'admin_7th_local' ||
              id == 'admin_5th_local',
        )
        .toList();
    if (localAdmins.isNotEmpty) {
      groups.add(CareerGroup(name: '지방행정직', careerIds: localAdmins));
    }

    // 전문행정직 그룹
    final specializedAdmins = careerIds
        .where(
          (id) =>
              id == 'tax_officer' ||
              id == 'customs_officer' ||
              id == 'job_counselor' ||
              id == 'statistics_officer' ||
              id == 'librarian' ||
              id == 'auditor' ||
              id == 'security_officer',
        )
        .toList();
    if (specializedAdmins.isNotEmpty) {
      groups.add(CareerGroup(name: '전문행정직', careerIds: specializedAdmins));
    }

    // 중등교사 그룹
    final secondaryTeachers = careerIds
        .where(
          (id) =>
              id == 'secondary_math_teacher' ||
              id == 'secondary_korean_teacher' ||
              id == 'secondary_english_teacher' ||
              id == 'secondary_science_teacher' ||
              id == 'secondary_social_teacher' ||
              id == 'secondary_arts_teacher',
        )
        .toList();
    if (secondaryTeachers.isNotEmpty) {
      groups.add(CareerGroup(name: '중등교사', careerIds: secondaryTeachers));
    }

    // 비교과 교사 그룹
    final nonSubjectTeachers = careerIds
        .where(
          (id) =>
              id == 'counselor_teacher' ||
              id == 'health_teacher' ||
              id == 'librarian_teacher' ||
              id == 'nutrition_teacher',
        )
        .toList();
    if (nonSubjectTeachers.isNotEmpty) {
      groups.add(CareerGroup(name: '비교과교사', careerIds: nonSubjectTeachers));
    }

    // 보건복지직 그룹
    final healthWelfare = careerIds
        .where(
          (id) =>
              id == 'public_health_officer' ||
              id == 'medical_technician' ||
              id == 'nurse' ||
              id == 'medical_officer' ||
              id == 'pharmacist' ||
              id == 'food_sanitation' ||
              id == 'social_worker',
        )
        .toList();
    if (healthWelfare.isNotEmpty) {
      groups.add(CareerGroup(name: '보건복지직', careerIds: healthWelfare));
    }

    // 공안직 그룹
    final publicSecurity = careerIds
        .where(
          (id) =>
              id == 'correction_officer' ||
              id == 'probation_officer' ||
              id == 'prosecution_officer' ||
              id == 'drug_investigation_officer' ||
              id == 'immigration_officer' ||
              id == 'railroad_police' ||
              id == 'security_guard',
        )
        .toList();
    if (publicSecurity.isNotEmpty) {
      groups.add(CareerGroup(name: '공안직', careerIds: publicSecurity));
    }

    // 군인 그룹
    final military = careerIds
        .where(
          (id) =>
              id == 'army' ||
              id == 'navy' ||
              id == 'air_force' ||
              id == 'military_civilian',
        )
        .toList();
    if (military.isNotEmpty) {
      groups.add(CareerGroup(name: '군인', careerIds: military));
    }

    // 기술직 - 공업 그룹
    final industrial = careerIds
        .where(
          (id) =>
              id == 'mechanical_engineer' ||
              id == 'electrical_engineer' ||
              id == 'electronics_engineer' ||
              id == 'chemical_engineer' ||
              id == 'shipbuilding_engineer' ||
              id == 'nuclear_engineer' ||
              id == 'metal_engineer' ||
              id == 'textile_engineer',
        )
        .toList();
    if (industrial.isNotEmpty) {
      groups.add(CareerGroup(name: '공업직', careerIds: industrial));
    }

    // 기술직 - 시설환경 그룹
    final facilities = careerIds
        .where(
          (id) =>
              id == 'civil_engineer' ||
              id == 'architect' ||
              id == 'landscape_architect' ||
              id == 'traffic_engineer' ||
              id == 'cadastral_officer' ||
              id == 'designer' ||
              id == 'environmental_officer',
        )
        .toList();
    if (facilities.isNotEmpty) {
      groups.add(CareerGroup(name: '시설환경직', careerIds: facilities));
    }

    // 기술직 - 농림수산 그룹
    final agriculture = careerIds
        .where(
          (id) =>
              id == 'agriculture_officer' ||
              id == 'plant_quarantine' ||
              id == 'livestock_officer' ||
              id == 'forestry_officer' ||
              id == 'marine_officer' ||
              id == 'fisheries_officer' ||
              id == 'ship_officer' ||
              id == 'veterinarian' ||
              id == 'agricultural_extension',
        )
        .toList();
    if (agriculture.isNotEmpty) {
      groups.add(CareerGroup(name: '농림수산직', careerIds: agriculture));
    }

    // 기술직 - IT통신 그룹
    final itComm = careerIds
        .where(
          (id) =>
              id == 'computer_officer' || id == 'broadcasting_communication',
        )
        .toList();
    if (itComm.isNotEmpty) {
      groups.add(CareerGroup(name: 'IT통신직', careerIds: itComm));
    }

    // 기술직 - 관리운영 그룹
    final management = careerIds
        .where(
          (id) =>
              id == 'facility_management' ||
              id == 'sanitation_worker' ||
              id == 'cook',
        )
        .toList();
    if (management.isNotEmpty) {
      groups.add(CareerGroup(name: '관리운영직', careerIds: management));
    }

    // 그룹화되지 않은 나머지 직렬들
    final allGroupedIds = groups.expand((g) => g.careerIds).toSet();
    final ungrouped = careerIds
        .where((id) => !allGroupedIds.contains(id))
        .toList();
    if (ungrouped.isNotEmpty) {
      groups.add(CareerGroup(name: '기타', careerIds: ungrouped));
    }

    return groups;
  }

  // ============================================================================
  // Single Source of Truth: LoungeDefinitions
  // ============================================================================
  //
  // 직렬명과 이모지는 LoungeDefinitions에서만 관리됩니다.
  // - getCareerDisplayName() → LoungeDefinitions 조회
  // - getCareerEmoji() → LoungeDefinitions 조회
  //
  // 이전에 사용되던 _careerIdToName, _careerIdToEmoji 맵은 제거되었습니다.
  // 모든 직렬 정보는 lib/features/community/domain/models/lounge_definitions.dart에서 관리합니다.
  // ============================================================================
}
