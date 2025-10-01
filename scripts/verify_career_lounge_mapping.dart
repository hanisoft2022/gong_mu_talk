// ignore_for_file: avoid_print

import '../lib/features/profile/domain/career_hierarchy.dart';
import '../lib/features/community/domain/models/lounge_model.dart';
import '../lib/features/community/domain/models/lounge_definitions.dart';

/// 직렬-라운지 매핑 검증 스크립트
/// 
/// 다음 사항을 검증:
/// 1. 모든 직렬이 CareerHierarchy에 정의되어 있는가?
/// 2. 모든 라운지의 requiredCareerIds가 유효한가?
/// 3. 고아 라운지(접근 가능한 직렬 없음) 확인
/// 4. 고아 직렬(라운지 없음) 확인
/// 
/// 실행 방법:
/// ```bash
/// dart run scripts/verify_career_lounge_mapping.dart
/// ```

void main() {
  print('🔍 직렬-라운지 매핑 검증 시작');
  print('=' * 60);

  var errorCount = 0;
  var warningCount = 0;

  // 1. 모든 정의된 직렬 ID 수집
  print('\n1️⃣  직렬 정의 검증');
  final allCareerIds = _getAllDefinedCareerIds();
  print('✅ 정의된 직렬: ${allCareerIds.length}개');

  // 2. 모든 라운지의 requiredCareerIds 검증
  print('\n2️⃣  라운지 requiredCareerIds 검증');
  final lounges = LoungeDefinitions.defaultLounges;
  for (final lounge in lounges) {
    // public 라운지는 스킵
    if (lounge.accessType == LoungeAccessType.public) {
      continue;
    }

    // requiredCareerIds가 비어있는지 확인
    if (lounge.requiredCareerIds.isEmpty &&
        lounge.accessType == LoungeAccessType.careerOnly) {
      print('⚠️  ${lounge.id}: careerOnly이지만 requiredCareerIds가 비어있음');
      warningCount++;
      continue;
    }

    // 각 careerID가 유효한지 확인
    for (final careerId in lounge.requiredCareerIds) {
      if (!allCareerIds.contains(careerId)) {
        print('❌ ${lounge.id}: 유효하지 않은 careerId "$careerId"');
        errorCount++;
      }
    }
  }

  if (errorCount == 0) {
    print('✅ 모든 라운지의 requiredCareerIds가 유효함');
  }

  // 3. 고아 라운지 확인 (접근 가능한 직렬이 없는 라운지)
  print('\n3️⃣  고아 라운지 확인');
  final orphanedLounges = <String>[];
  for (final lounge in lounges) {
    if (lounge.accessType == LoungeAccessType.public) {
      continue; // public은 제외
    }

    // requiredCareerIds로 접근 가능한지 확인
    var accessible = false;
    for (final careerId in allCareerIds) {
      final hierarchy = CareerHierarchy.fromSpecificCareer(careerId);
      final accessibleLoungeIds = _getAccessibleLoungeIds(hierarchy);

      if (accessibleLoungeIds.contains(lounge.id)) {
        accessible = true;
        break;
      }
    }

    if (!accessible) {
      orphanedLounges.add(lounge.id);
      print('⚠️  고아 라운지: ${lounge.id} (${lounge.name})');
      warningCount++;
    }
  }

  if (orphanedLounges.isEmpty) {
    print('✅ 고아 라운지 없음');
  }

  // 4. 고아 직렬 확인 (전체 라운지만 접근 가능한 직렬)
  print('\n4️⃣  전체 라운지만 접근 가능한 직렬 확인');
  final onlyAllAccessCareers = <String>[];
  for (final careerId in allCareerIds) {
    final hierarchy = CareerHierarchy.fromSpecificCareer(careerId);
    final accessibleIds = _getAccessibleLoungeIds(hierarchy);

    // 전체 라운지만 접근 가능한 경우
    if (accessibleIds.length == 1 && accessibleIds.first == 'all') {
      onlyAllAccessCareers.add(careerId);
      print('ℹ️  전체만 접근: $careerId');
    }
  }

  print('\n  전체 라운지만 접근 가능한 직렬: ${onlyAllAccessCareers.length}개');
  print('  (프라이버시 보호 정책)');

  // 5. 계층 구조 검증 (부모-자식 관계)
  print('\n5️⃣  계층 구조 검증');
  for (final lounge in lounges) {
    if (lounge.parentLoungeId != null) {
      final parentExists = lounges.any((l) => l.id == lounge.parentLoungeId);
      if (!parentExists) {
        print('❌ ${lounge.id}: 존재하지 않는 부모 "${lounge.parentLoungeId}"');
        errorCount++;
      }
    }
  }

  if (errorCount == 0) {
    print('✅ 계층 구조 유효함');
  }

  // 6. 중복 ID 확인
  print('\n6️⃣  중복 ID 확인');
  final loungeIds = lounges.map((l) => l.id).toList();
  final uniqueIds = loungeIds.toSet();
  if (loungeIds.length != uniqueIds.length) {
    print('❌ 중복된 라운지 ID 발견!');
    errorCount++;
  } else {
    print('✅ 중복 ID 없음');
  }

  // 7. 통계
  print('\n📊 통계');
  print('  - 총 직렬: ${allCareerIds.length}개');
  print('  - 총 라운지: ${lounges.length}개');
  print('  - 프라이버시 보호 직렬: ${onlyAllAccessCareers.length}개');
  print('  - 고아 라운지: ${orphanedLounges.length}개');

  // 최종 결과
  print('\n' + '=' * 60);
  if (errorCount == 0 && warningCount == 0) {
    print('✅ 검증 완료 - 문제 없음!');
  } else {
    print('⚠️  검증 완료:');
    print('  - 오류: $errorCount개');
    print('  - 경고: $warningCount개');
  }
}

/// 모든 정의된 직렬 ID 수집
List<String> _getAllDefinedCareerIds() {
  final careers = <String>[
    // 교육공무원 - 교사
    'elementary_teacher',
    'kindergarten_teacher',
    'special_education_teacher',
    'secondary_math_teacher',
    'secondary_korean_teacher',
    'secondary_english_teacher',
    'secondary_science_teacher',
    'secondary_social_teacher',
    'secondary_arts_teacher',
    'counselor_teacher',
    'health_teacher',
    'librarian_teacher',
    'nutrition_teacher',

    // 교육행정직
    'education_admin_9th_national',
    'education_admin_7th_national',
    'education_admin_9th_local',
    'education_admin_7th_local',

    // 행정직
    'admin_9th_national',
    'admin_7th_national',
    'admin_5th_national',
    'admin_9th_local',
    'admin_7th_local',
    'admin_5th_local',
    'tax_officer',
    'customs_officer',
    'job_counselor',
    'statistics_officer',
    'librarian',
    'auditor',
    'security_officer',

    // 보건복지직
    'public_health_officer',
    'medical_technician',
    'nurse',
    'medical_officer',
    'pharmacist',
    'food_sanitation',
    'social_worker',

    // 공안직
    'correction_officer',
    'probation_officer',
    'prosecution_officer',
    'drug_investigation_officer',
    'immigration_officer',
    'railroad_police',
    'security_guard',

    // 치안/안전
    'police',
    'firefighter',
    'coast_guard',

    // 군인
    'army',
    'navy',
    'air_force',
    'military_civilian',

    // 기술직
    'mechanical_engineer',
    'electrical_engineer',
    'electronics_engineer',
    'chemical_engineer',
    'shipbuilding_engineer',
    'nuclear_engineer',
    'metal_engineer',
    'textile_engineer',
    'civil_engineer',
    'architect',
    'landscape_architect',
    'traffic_engineer',
    'cadastral_officer',
    'designer',
    'environmental_officer',
    'agriculture_officer',
    'plant_quarantine',
    'livestock_officer',
    'forestry_officer',
    'marine_officer',
    'fisheries_officer',
    'ship_officer',
    'veterinarian',
    'agricultural_extension',
    'computer_officer',
    'broadcasting_communication',
    'facility_management',
    'sanitation_worker',
    'cook',

    // 기타
    'postal_service',
    'researcher',

    // 신규 직렬
    'judge',
    'prosecutor',
    'diplomat_5th',
    'diplomat_consular',
    'diplomat_3rd',
    'curator',
    'cultural_heritage',
    'meteorologist',
    'disaster_safety',
    'nursing_assistant',
    'health_care',
    'national_assembly',
    'constitutional_court',
    'election_commission',
    'audit_board',
    'human_rights_commission',

    // 프라이버시 보호 직렬
    'constitutional_researcher',
    'security_service',
    'intelligence_service',
    'aviation',
    'broadcasting_stage',
    'driving',
  ];

  return careers;
}

/// 접근 가능한 라운지 ID 목록 반환
List<String> _getAccessibleLoungeIds(CareerHierarchy hierarchy) {
  final ids = <String>['all'];

  if (hierarchy.level2 != null) {
    ids.add(hierarchy.level2!);
  }
  if (hierarchy.level3 != null) {
    ids.add(hierarchy.level3!);
  }
  if (hierarchy.level4 != null) {
    ids.add(hierarchy.level4!);
  }

  return ids;
}
