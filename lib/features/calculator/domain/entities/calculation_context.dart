import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/performance_grade.dart';

/// 월별 실수령액 계산을 위한 컨텍스트
///
/// 여러 파라미터를 하나의 객체로 묶어 가독성과 유지보수성 향상
class CalculationContext extends Equatable {
  const CalculationContext({
    required this.profile,
    required this.year,
    required this.hasSpouse,
    required this.numberOfChildren,
    this.isHomeroom = false,
    this.hasPosition = false,
    this.performanceGrade = PerformanceGrade.A,
  });

  /// 교사 프로필
  final TeacherProfile profile;

  /// 계산 년도
  final int year;

  /// 배우자 유무
  final bool hasSpouse;

  /// 자녀 수
  final int numberOfChildren;

  /// 담임 여부
  final bool isHomeroom;

  /// 보직 여부
  final bool hasPosition;

  /// 성과상여금 등급 (기본값: A등급)
  final PerformanceGrade performanceGrade;

  @override
  List<Object?> get props => [
        profile,
        year,
        hasSpouse,
        numberOfChildren,
        isHomeroom,
        hasPosition,
        performanceGrade,
      ];

  CalculationContext copyWith({
    TeacherProfile? profile,
    int? year,
    bool? hasSpouse,
    int? numberOfChildren,
    bool? isHomeroom,
    bool? hasPosition,
    PerformanceGrade? performanceGrade,
  }) {
    return CalculationContext(
      profile: profile ?? this.profile,
      year: year ?? this.year,
      hasSpouse: hasSpouse ?? this.hasSpouse,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      isHomeroom: isHomeroom ?? this.isHomeroom,
      hasPosition: hasPosition ?? this.hasPosition,
      performanceGrade: performanceGrade ?? this.performanceGrade,
    );
  }
}
