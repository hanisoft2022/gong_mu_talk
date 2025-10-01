import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 라운지 타입 - 계층적 구조 표현
enum LoungeType {
  all, // 전체 라운지
  category, // 대분류 라운지 (교사, 행정직 등)
  specific, // 세부 직렬 라운지 (초등교사, 중등수학교사 등)
}

/// 라운지 접근 권한 타입
enum LoungeAccessType {
  public, // 모든 공무원 접근 가능
  careerOnly, // 특정 직렬만 접근 가능
  verified, // 인증된 사용자만 접근 가능
}

/// 라운지 모델 - 계층적 공무원 커뮤니티를 위한 모델
class Lounge extends Equatable {
  const Lounge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.accessType,
    required this.requiredCareerIds,
    this.shortName,
    this.description,
    this.memberCount = 0,
    this.parentLoungeId,
    this.childLoungeIds = const [],
    this.order = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// 라운지 고유 ID
  final String id;

  /// 라운지 전체 이름
  final String name;

  /// 라운지 이모지
  final String emoji;

  /// 라운지 타입
  final LoungeType type;

  /// 접근 권한 타입
  final LoungeAccessType accessType;

  /// 접근 가능한 직렬 ID 목록
  final List<String> requiredCareerIds;

  /// 짧은 이름 (UI 표시용)
  final String? shortName;

  /// 라운지 설명
  final String? description;

  /// 멤버 수
  final int memberCount;

  /// 부모 라운지 ID (계층 구조)
  final String? parentLoungeId;

  /// 자식 라운지 ID 목록 (계층 구조)
  final List<String> childLoungeIds;

  /// 정렬 순서
  final int order;

  /// 활성 상태
  final bool isActive;

  /// 생성 시간
  final DateTime? createdAt;

  /// 수정 시간
  final DateTime? updatedAt;

  /// 표시용 텍스트 (드롭다운, 탭 등)
  String get displayText {
    final displayName = shortName ?? name;
    final countText = memberCount > 0 ? ' ($memberCount명)' : '';
    return '$emoji $displayName$countText';
  }

  /// 상세 표시 텍스트
  String get fullDisplayText {
    final countText = memberCount > 0 ? ' ($memberCount명)' : '';
    return '$emoji $name$countText';
  }

  /// 특정 직렬이 접근 가능한지 확인
  bool canAccess(String? careerTrackId) {
    if (accessType == LoungeAccessType.public) {
      return true;
    }

    if (careerTrackId == null) {
      return false;
    }

    return requiredCareerIds.contains(careerTrackId);
  }

  /// 여러 직렬 중 하나라도 접근 가능한지 확인
  bool canAccessWithAny(List<String> careerTrackIds) {
    if (accessType == LoungeAccessType.public) {
      return true;
    }

    return careerTrackIds.any((id) => requiredCareerIds.contains(id));
  }

  /// 통합 라운지 여부 (여러 직렬이 모이는 라운지)
  bool get isUnifiedLounge => requiredCareerIds.length > 1;

  /// 접근 가능한 직렬 수
  int get accessibleCareerCount => requiredCareerIds.length;

  /// Firestore 저장용 Map 변환
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'emoji': emoji,
      'type': type.name,
      'accessType': accessType.name,
      'requiredCareerIds': requiredCareerIds,
      'shortName': shortName,
      'description': description,
      'memberCount': memberCount,
      'parentLoungeId': parentLoungeId,
      'childLoungeIds': childLoungeIds,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Firestore DocumentSnapshot에서 생성
  static Lounge fromSnapshot(DocumentSnapshot<Map<String, Object?>> snapshot) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('Lounge document ${snapshot.id} has no data');
    }

    return fromMap(snapshot.id, data);
  }

  /// Map에서 생성
  static Lounge fromMap(String id, Map<String, Object?> data) {
    return Lounge(
      id: id,
      name: (data['name'] as String?) ?? '이름 없음',
      emoji: (data['emoji'] as String?) ?? '🏛️',
      type: _parseType(data['type']),
      accessType: _parseAccessType(data['accessType']),
      requiredCareerIds: _parseStringList(data['requiredCareerIds']),
      shortName: data['shortName'] as String?,
      description: data['description'] as String?,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      parentLoungeId: data['parentLoungeId'] as String?,
      childLoungeIds: _parseStringList(data['childLoungeIds']),
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  static LoungeType _parseType(Object? raw) {
    if (raw is String) {
      return LoungeType.values.firstWhere(
        (LoungeType value) => value.name == raw,
        orElse: () => LoungeType.specific,
      );
    }
    return LoungeType.specific;
  }

  static LoungeAccessType _parseAccessType(Object? raw) {
    if (raw is String) {
      return LoungeAccessType.values.firstWhere(
        (LoungeAccessType value) => value.name == raw,
        orElse: () => LoungeAccessType.careerOnly,
      );
    }
    return LoungeAccessType.careerOnly;
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  Lounge copyWith({
    String? id,
    String? name,
    String? emoji,
    LoungeType? type,
    LoungeAccessType? accessType,
    List<String>? requiredCareerIds,
    String? shortName,
    String? description,
    int? memberCount,
    String? parentLoungeId,
    List<String>? childLoungeIds,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lounge(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      accessType: accessType ?? this.accessType,
      requiredCareerIds: requiredCareerIds ?? this.requiredCareerIds,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      parentLoungeId: parentLoungeId ?? this.parentLoungeId,
      childLoungeIds: childLoungeIds ?? this.childLoungeIds,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    emoji,
    type,
    accessType,
    requiredCareerIds,
    shortName,
    description,
    memberCount,
    parentLoungeId,
    childLoungeIds,
    order,
    isActive,
    createdAt,
    updatedAt,
  ];
}

/// 라운지 설정 - 기본 라운지 목록 정의
class LoungeDefinitions {
  static const List<Lounge> defaultLounges = [
    // 전체 라운지
    Lounge(
      id: 'all',
      name: '전체',
      emoji: '🏛️',
      shortName: '전체',
      type: LoungeType.all,
      accessType: LoungeAccessType.public,
      requiredCareerIds: [],
      memberCount: 1000000,
      description: '모든 공무원이 참여하는 라운지',
      order: 0,
    ),

    // 교육 분야
    Lounge(
      id: 'teacher',
      name: '교사',
      emoji: '📚',
      shortName: '교사',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'elementary_teacher',
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
      ],
      memberCount: 430000,
      description: '모든 교사가 참여하는 라운지',
      order: 1,
    ),

    Lounge(
      id: 'elementary_teacher',
      name: '초등교사',
      emoji: '🏫',
      shortName: '초등교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['elementary_teacher'],
      parentLoungeId: 'teacher',
      memberCount: 180000,
      description: '초등교사 전용 라운지',
      order: 11,
    ),

    Lounge(
      id: 'secondary_teacher',
      name: '중등교사',
      emoji: '🎓',
      shortName: '중등교사',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'secondary_math_teacher',
        'secondary_korean_teacher',
        'secondary_english_teacher',
        'secondary_science_teacher',
        'secondary_social_teacher',
        'secondary_arts_teacher',
      ],
      parentLoungeId: 'teacher',
      memberCount: 200000,
      description: '중등교사 전용 라운지',
      order: 12,
    ),

    // 중등교과별 라운지
    Lounge(
      id: 'secondary_math_teacher',
      name: '중등수학교사',
      emoji: '📐',
      shortName: '중등수학교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['secondary_math_teacher'],
      parentLoungeId: 'secondary_teacher',
      memberCount: 30000,
      description: '중등 수학교사 전용 라운지',
      order: 121,
    ),

    Lounge(
      id: 'secondary_korean_teacher',
      name: '중등국어교사',
      emoji: '📖',
      shortName: '중등국어교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['secondary_korean_teacher'],
      parentLoungeId: 'secondary_teacher',
      memberCount: 30000,
      description: '중등 국어교사 전용 라운지',
      order: 122,
    ),

    Lounge(
      id: 'secondary_english_teacher',
      name: '중등영어교사',
      emoji: '🌍',
      shortName: '중등영어교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['secondary_english_teacher'],
      parentLoungeId: 'secondary_teacher',
      memberCount: 25000,
      description: '중등 영어교사 전용 라운지',
      order: 123,
    ),

    Lounge(
      id: 'secondary_science_teacher',
      name: '중등과학교사',
      emoji: '🔬',
      shortName: '중등과학교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['secondary_science_teacher'],
      parentLoungeId: 'secondary_teacher',
      memberCount: 30000,
      description: '중등 과학교사 전용 라운지',
      order: 124,
    ),

    Lounge(
      id: 'secondary_social_teacher',
      name: '중등사회교사',
      emoji: '🌏',
      shortName: '중등사회교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['secondary_social_teacher'],
      parentLoungeId: 'secondary_teacher',
      memberCount: 25000,
      description: '중등 사회교사 전용 라운지',
      order: 125,
    ),

    Lounge(
      id: 'secondary_arts_teacher',
      name: '중등예체능교사',
      emoji: '🎨',
      shortName: '중등예체능교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['secondary_arts_teacher'],
      parentLoungeId: 'secondary_teacher',
      memberCount: 60000,
      description: '중등 예체능교사 전용 라운지',
      order: 126,
    ),

    // 유치원/특수교육 교사
    Lounge(
      id: 'kindergarten_teacher',
      name: '유치원교사',
      emoji: '👶',
      shortName: '유치원교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['kindergarten_teacher'],
      parentLoungeId: 'teacher',
      memberCount: 5000,
      description: '유치원교사 전용 라운지',
      order: 13,
    ),

    Lounge(
      id: 'special_education_teacher',
      name: '특수교육교사',
      emoji: '🤝',
      shortName: '특수교육교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['special_education_teacher'],
      parentLoungeId: 'teacher',
      memberCount: 4000,
      description: '특수교육교사 전용 라운지',
      order: 14,
    ),

    // 비교과 교사 통합 라운지
    Lounge(
      id: 'non_subject_teacher',
      name: '비교과교사',
      emoji: '💼',
      shortName: '비교과교사',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'counselor_teacher',
        'health_teacher',
        'librarian_teacher',
        'nutrition_teacher',
      ],
      parentLoungeId: 'teacher',
      memberCount: 15000,
      description: '상담·보건·사서·영양 교사 라운지',
      order: 15,
    ),

    // 행정직
    Lounge(
      id: 'admin',
      name: '행정직',
      emoji: '🗂️',
      shortName: '행정직',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
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
      ],
      memberCount: 280000,
      description: '행정직 공무원 라운지',
      order: 2,
    ),

    // 국가 행정직
    Lounge(
      id: 'national_admin',
      name: '국가행정직',
      emoji: '🏛️',
      shortName: '국가행정직',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'admin_9th_national',
        'admin_7th_national',
        'admin_5th_national',
      ],
      parentLoungeId: 'admin',
      memberCount: 80000,
      description: '국가직 행정공무원 라운지',
      order: 21,
    ),

    Lounge(
      id: 'admin_9th_national',
      name: '9급 국가행정직',
      emoji: '📋',
      shortName: '9급 국가행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['admin_9th_national'],
      parentLoungeId: 'national_admin',
      memberCount: 30000,
      description: '9급 국가직 행정공무원 라운지',
      order: 211,
    ),

    Lounge(
      id: 'admin_7th_national',
      name: '7급 국가행정직',
      emoji: '📊',
      shortName: '7급 국가행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['admin_7th_national'],
      parentLoungeId: 'national_admin',
      memberCount: 30000,
      description: '7급 국가직 행정공무원 라운지',
      order: 212,
    ),

    Lounge(
      id: 'admin_5th_national',
      name: '5급 국가행정직',
      emoji: '💼',
      shortName: '5급 국가행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['admin_5th_national'],
      parentLoungeId: 'national_admin',
      memberCount: 20000,
      description: '5급 국가직 행정공무원 라운지',
      order: 213,
    ),

    // 지방 행정직
    Lounge(
      id: 'local_admin',
      name: '지방행정직',
      emoji: '🏢',
      shortName: '지방행정직',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'admin_9th_local',
        'admin_7th_local',
        'admin_5th_local',
      ],
      parentLoungeId: 'admin',
      memberCount: 150000,
      description: '지방직 행정공무원 라운지',
      order: 22,
    ),

    Lounge(
      id: 'admin_9th_local',
      name: '9급 지방행정직',
      emoji: '📋',
      shortName: '9급 지방행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['admin_9th_local'],
      parentLoungeId: 'local_admin',
      memberCount: 80000,
      description: '9급 지방직 행정공무원 라운지',
      order: 221,
    ),

    Lounge(
      id: 'admin_7th_local',
      name: '7급 지방행정직',
      emoji: '📊',
      shortName: '7급 지방행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['admin_7th_local'],
      parentLoungeId: 'local_admin',
      memberCount: 50000,
      description: '7급 지방직 행정공무원 라운지',
      order: 222,
    ),

    Lounge(
      id: 'admin_5th_local',
      name: '5급 지방행정직',
      emoji: '💼',
      shortName: '5급 지방행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['admin_5th_local'],
      parentLoungeId: 'local_admin',
      memberCount: 20000,
      description: '5급 지방직 행정공무원 라운지',
      order: 223,
    ),

    // 세무·관세직
    Lounge(
      id: 'tax_customs',
      name: '세무·관세직',
      emoji: '💰',
      shortName: '세무·관세직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['tax_officer', 'customs_officer'],
      parentLoungeId: 'admin',
      memberCount: 25000,
      description: '세무직 및 관세직 공무원 라운지',
      order: 23,
    ),

    // 전문행정직
    Lounge(
      id: 'specialized_admin',
      name: '전문행정직',
      emoji: '📋',
      shortName: '전문행정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'job_counselor',
        'statistics_officer',
        'librarian',
        'auditor',
        'security_officer',
      ],
      parentLoungeId: 'admin',
      memberCount: 30000,
      description: '고용노동·통계·사서·감사·방호직 라운지',
      order: 24,
    ),

    // 보건복지직
    Lounge(
      id: 'health_welfare',
      name: '보건복지직',
      emoji: '🏥',
      shortName: '보건복지직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'public_health_officer',
        'medical_technician',
        'nurse',
        'medical_officer',
        'pharmacist',
        'food_sanitation',
        'social_worker',
      ],
      memberCount: 80000,
      description: '보건·의료·간호·약무·복지직 라운지',
      order: 5,
    ),

    // 공안직
    Lounge(
      id: 'public_security',
      name: '공안직',
      emoji: '⚖️',
      shortName: '공안직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'correction_officer',
        'probation_officer',
        'prosecution_officer',
        'drug_investigation_officer',
        'immigration_officer',
        'railroad_police',
        'security_guard',
      ],
      memberCount: 50000,
      description: '교정·검찰·마약수사·출입국관리직 라운지',
      order: 6,
    ),

    // 치안/안전
    Lounge(
      id: 'police',
      name: '경찰관',
      emoji: '👮‍♂️',
      shortName: '경찰관',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['police'],
      memberCount: 120000,
      description: '경찰관 전용 라운지',
      order: 3,
    ),

    Lounge(
      id: 'firefighter',
      name: '소방관',
      emoji: '👨‍🚒',
      shortName: '소방관',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['firefighter'],
      memberCount: 50000,
      description: '소방관 전용 라운지',
      order: 4,
    ),

    Lounge(
      id: 'coast_guard',
      name: '해양경찰',
      emoji: '🌊',
      shortName: '해양경찰',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['coast_guard'],
      memberCount: 10000,
      description: '해양경찰 전용 라운지',
      order: 41,
    ),

    // 군인
    Lounge(
      id: 'military',
      name: '군인',
      emoji: '🎖️',
      shortName: '군인',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['army', 'navy', 'air_force', 'military_civilian'],
      memberCount: 80000,
      description: '군인 전용 라운지',
      order: 7,
    ),

    Lounge(
      id: 'army',
      name: '육군',
      emoji: '🪖',
      shortName: '육군',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['army'],
      parentLoungeId: 'military',
      memberCount: 50000,
      description: '육군 전용 라운지',
      order: 71,
    ),

    Lounge(
      id: 'navy',
      name: '해군',
      emoji: '⚓',
      shortName: '해군',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['navy'],
      parentLoungeId: 'military',
      memberCount: 15000,
      description: '해군 전용 라운지',
      order: 72,
    ),

    Lounge(
      id: 'air_force',
      name: '공군',
      emoji: '✈️',
      shortName: '공군',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['air_force'],
      parentLoungeId: 'military',
      memberCount: 15000,
      description: '공군 전용 라운지',
      order: 73,
    ),

    Lounge(
      id: 'military_civilian',
      name: '군무원',
      emoji: '🎖️',
      shortName: '군무원',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['military_civilian'],
      parentLoungeId: 'military',
      memberCount: 30000,
      description: '군무원 전용 라운지',
      order: 74,
    ),

    // 기술직
    Lounge(
      id: 'technical',
      name: '기술직',
      emoji: '⚙️',
      shortName: '기술직',
      type: LoungeType.category,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
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
      ],
      memberCount: 300000,
      description: '모든 기술직 공무원 라운지',
      order: 8,
    ),

    Lounge(
      id: 'industrial_engineer',
      name: '공업직',
      emoji: '⚙️',
      shortName: '공업직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'mechanical_engineer',
        'electrical_engineer',
        'electronics_engineer',
        'chemical_engineer',
        'shipbuilding_engineer',
        'nuclear_engineer',
        'metal_engineer',
        'textile_engineer',
      ],
      parentLoungeId: 'technical',
      memberCount: 50000,
      description: '기계·전기·전자·화공직 등 공업 기술직',
      order: 81,
    ),

    Lounge(
      id: 'facilities_environment',
      name: '시설환경직',
      emoji: '🏗️',
      shortName: '시설환경직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'civil_engineer',
        'architect',
        'landscape_architect',
        'traffic_engineer',
        'cadastral_officer',
        'designer',
        'environmental_officer',
      ],
      parentLoungeId: 'technical',
      memberCount: 47000,
      description: '토목·건축·환경직 등 시설환경 기술직',
      order: 82,
    ),

    Lounge(
      id: 'agriculture_forestry_fisheries',
      name: '농림수산직',
      emoji: '🌾',
      shortName: '농림수산직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: [
        'agriculture_officer',
        'plant_quarantine',
        'livestock_officer',
        'forestry_officer',
        'marine_officer',
        'fisheries_officer',
        'ship_officer',
        'veterinarian',
        'agricultural_extension',
      ],
      parentLoungeId: 'technical',
      memberCount: 70000,
      description: '농업·수산·축산·수의직 등',
      order: 83,
    ),

    Lounge(
      id: 'it_communications',
      name: 'IT통신직',
      emoji: '💻',
      shortName: 'IT통신직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['computer_officer', 'broadcasting_communication'],
      parentLoungeId: 'technical',
      memberCount: 20000,
      description: '전산·방송통신직 라운지',
      order: 84,
    ),

    Lounge(
      id: 'management_operations',
      name: '관리운영직',
      emoji: '🏢',
      shortName: '관리운영직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['facility_management', 'sanitation_worker', 'cook'],
      parentLoungeId: 'technical',
      memberCount: 35000,
      description: '시설관리·위생·조리직 라운지',
      order: 85,
    ),

    // 기타 직렬
    Lounge(
      id: 'postal_service',
      name: '우정직',
      emoji: '📮',
      shortName: '우정직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['postal_service'],
      memberCount: 50000,
      description: '우정직 공무원 라운지',
      order: 9,
    ),

    Lounge(
      id: 'researcher',
      name: '연구직',
      emoji: '🔬',
      shortName: '연구직',
      type: LoungeType.specific,
      accessType: LoungeAccessType.careerOnly,
      requiredCareerIds: ['researcher'],
      memberCount: 20000,
      description: '연구직 공무원 라운지',
      order: 10,
    ),
  ];
}
