import 'package:equatable/equatable.dart';

/// 라운지 정보를 담는 클래스
class LoungeInfo extends Equatable {
  const LoungeInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.shortName,
    this.memberCount = 0,
    this.description,
  });

  /// 라운지 고유 ID
  final String id;

  /// 라운지 표시명
  final String name;

  /// 라운지 이모지
  final String emoji;

  /// 짧은 이름 (탭/드롭다운용)
  final String shortName;

  /// 멤버 수
  final int memberCount;

  /// 라운지 설명
  final String? description;

  /// 드롭다운에 표시될 텍스트
  String get displayText {
    final countText = memberCount > 0 ? ' ($memberCount명)' : '';
    return '$emoji $shortName$countText';
  }

  /// 상세 표시 텍스트
  String get fullDisplayText {
    final countText = memberCount > 0 ? ' ($memberCount명)' : '';
    return '$emoji $name$countText';
  }

  LoungeInfo copyWith({
    String? id,
    String? name,
    String? emoji,
    String? shortName,
    int? memberCount,
    String? description,
  }) {
    return LoungeInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      shortName: shortName ?? this.shortName,
      memberCount: memberCount ?? this.memberCount,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    emoji,
    shortName,
    memberCount,
    description,
  ];
}
