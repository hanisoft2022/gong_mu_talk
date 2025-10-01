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
