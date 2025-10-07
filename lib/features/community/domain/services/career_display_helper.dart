/// 직렬 그룹 정보
library;

class CareerGroup {
  const CareerGroup({required this.name, required this.careerIds});

  final String name;
  final List<String> careerIds;
}

/// 직렬 ID를 한글 표시명으로 변환하는 헬퍼 클래스
class CareerDisplayHelper {
  /// 직렬 ID를 한글 이름으로 변환
  static String getCareerDisplayName(String careerId) {
    return _careerIdToName[careerId] ?? careerId;
  }

  /// 직렬 ID를 이모지로 변환
  static String getCareerEmoji(String careerId) {
    return _careerIdToEmoji[careerId] ?? '👤';
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

  /// 직렬 ID → 한글 이름 매핑
  static const Map<String, String> _careerIdToName = {
    // 교육공무원
    'elementary_teacher': '초등교사',
    'secondary_math_teacher': '중등수학교사',
    'secondary_korean_teacher': '중등국어교사',
    'secondary_english_teacher': '중등영어교사',
    'secondary_science_teacher': '중등과학교사',
    'secondary_social_teacher': '중등사회교사',
    'secondary_arts_teacher': '중등예체능교사',
    'kindergarten_teacher': '유치원교사',
    'special_education_teacher': '특수교육교사',
    'counselor_teacher': '상담교사',
    'health_teacher': '보건교사',
    'librarian_teacher': '사서교사',
    'nutrition_teacher': '영양교사',

    // 행정직
    'admin_9th_national': '9급 국가행정직',
    'admin_7th_national': '7급 국가행정직',
    'admin_5th_national': '5급 국가행정직',
    'admin_9th_local': '9급 지방행정직',
    'admin_7th_local': '7급 지방행정직',
    'admin_5th_local': '5급 지방행정직',
    'tax_officer': '세무직',
    'customs_officer': '관세직',
    'job_counselor': '고용노동직',
    'statistics_officer': '통계직',
    'librarian': '사서직',
    'auditor': '감사직',
    'security_officer': '방호직',

    // 보건복지직
    'public_health_officer': '보건직',
    'medical_technician': '의료기술직',
    'nurse': '간호직',
    'medical_officer': '의무직',
    'pharmacist': '약무직',
    'food_sanitation': '식품위생직',
    'social_worker': '사회복지직',

    // 공안직
    'correction_officer': '교정직',
    'probation_officer': '보호직',
    'prosecution_officer': '검찰직',
    'drug_investigation_officer': '마약수사직',
    'immigration_officer': '출입국관리직',
    'railroad_police': '철도경찰',
    'security_guard': '경비직',

    // 치안/안전
    'police': '경찰',
    'firefighter': '소방',
    'coast_guard': '해양경찰',

    // 군인
    'army': '육군',
    'navy': '해군',
    'air_force': '공군',
    'military_civilian': '군무원',

    // 기술직
    'mechanical_engineer': '기계직',
    'electrical_engineer': '전기직',
    'electronics_engineer': '전자직',
    'chemical_engineer': '화공직',
    'shipbuilding_engineer': '조선직',
    'nuclear_engineer': '원자력직',
    'metal_engineer': '금속직',
    'textile_engineer': '섬유직',
    'civil_engineer': '토목직',
    'architect': '건축직',
    'landscape_architect': '조경직',
    'traffic_engineer': '교통직',
    'cadastral_officer': '지적직',
    'designer': '디자인직',
    'environmental_officer': '환경직',
    'agriculture_officer': '농업직',
    'plant_quarantine': '식물검역직',
    'livestock_officer': '축산직',
    'forestry_officer': '산림직',
    'marine_officer': '해양수산직',
    'fisheries_officer': '수산직',
    'ship_officer': '항해직',
    'veterinarian': '수의직',
    'agricultural_extension': '농촌지도직',
    'computer_officer': '전산직',
    'broadcasting_communication': '방송통신직',
    'facility_management': '시설관리직',
    'sanitation_worker': '위생직',
    'cook': '조리직',

    // 기타
    'postal_service': '우정직',
    'researcher': '연구직',
  };

  /// 직렬 ID → 이모지 매핑
  static const Map<String, String> _careerIdToEmoji = {
    // 교육공무원
    'elementary_teacher': '🏫',
    'secondary_math_teacher': '📐',
    'secondary_korean_teacher': '📖',
    'secondary_english_teacher': '🌍',
    'secondary_science_teacher': '🔬',
    'secondary_social_teacher': '🌏',
    'secondary_arts_teacher': '🎨',
    'kindergarten_teacher': '👶',
    'special_education_teacher': '🤝',
    'counselor_teacher': '💬',
    'health_teacher': '🏥',
    'librarian_teacher': '📚',
    'nutrition_teacher': '🍎',

    // 행정직
    'admin_9th_national': '🏛️',
    'admin_7th_national': '🏛️',
    'admin_5th_national': '🏛️',
    'admin_9th_local': '🏢',
    'admin_7th_local': '🏢',
    'admin_5th_local': '🏢',
    'tax_officer': '💰',
    'customs_officer': '🛃',
    'job_counselor': '💼',
    'statistics_officer': '📊',
    'librarian': '📚',
    'auditor': '🔍',
    'security_officer': '🔒',

    // 보건복지직
    'public_health_officer': '🏥',
    'medical_technician': '🩺',
    'nurse': '💉',
    'medical_officer': '⚕️',
    'pharmacist': '💊',
    'food_sanitation': '🍴',
    'social_worker': '🤲',

    // 공안직
    'correction_officer': '⚖️',
    'probation_officer': '⚖️',
    'prosecution_officer': '⚖️',
    'drug_investigation_officer': '🚨',
    'immigration_officer': '🛂',
    'railroad_police': '🚂',
    'security_guard': '🛡️',

    // 치안/안전
    'police': '👮‍♂️',
    'firefighter': '👨‍🚒',
    'coast_guard': '🌊',

    // 군인
    'army': '🪖',
    'navy': '⚓',
    'air_force': '✈️',
    'military_civilian': '🎖️',

    // 기술직 - 공업
    'mechanical_engineer': '⚙️',
    'electrical_engineer': '⚡',
    'electronics_engineer': '🔌',
    'chemical_engineer': '🧪',
    'shipbuilding_engineer': '🚢',
    'nuclear_engineer': '⚛️',
    'metal_engineer': '🔩',
    'textile_engineer': '🧵',

    // 기술직 - 시설환경
    'civil_engineer': '🏗️',
    'architect': '🏛️',
    'landscape_architect': '🌳',
    'traffic_engineer': '🚦',
    'cadastral_officer': '🗺️',
    'designer': '🎨',
    'environmental_officer': '♻️',

    // 기술직 - 농림수산
    'agriculture_officer': '🌾',
    'plant_quarantine': '🌱',
    'livestock_officer': '🐄',
    'forestry_officer': '🌲',
    'marine_officer': '🌊',
    'fisheries_officer': '🐟',
    'ship_officer': '⛴️',
    'veterinarian': '🐕',
    'agricultural_extension': '👨‍🌾',

    // 기술직 - IT통신
    'computer_officer': '💻',
    'broadcasting_communication': '📡',

    // 기술직 - 관리운영
    'facility_management': '🔧',
    'sanitation_worker': '🧹',
    'cook': '👨‍🍳',

    // 기타
    'postal_service': '📮',
    'researcher': '🔬',
  };
}
