import 'package:equatable/equatable.dart';

/// 수당 정보
class Allowance extends Equatable {
  const Allowance({
    this.homeroom = 0,
    this.headTeacher = 0,
    this.family = 0,
    this.veteran = 0,
    this.other1 = 0,
    this.other2 = 0,
  });

  /// 담임수당
  final int homeroom;

  /// 부장수당
  final int headTeacher;

  /// 가족수당
  final int family;

  /// 원로수당
  final int veteran;

  /// 기타수당 1
  final int other1;

  /// 기타수당 2
  final int other2;

  @override
  List<Object?> get props => [
        homeroom,
        headTeacher,
        family,
        veteran,
        other1,
        other2,
      ];

  Allowance copyWith({
    int? homeroom,
    int? headTeacher,
    int? family,
    int? veteran,
    int? other1,
    int? other2,
  }) {
    return Allowance(
      homeroom: homeroom ?? this.homeroom,
      headTeacher: headTeacher ?? this.headTeacher,
      family: family ?? this.family,
      veteran: veteran ?? this.veteran,
      other1: other1 ?? this.other1,
      other2: other2 ?? this.other2,
    );
  }
}
