import 'package:equatable/equatable.dart';

/// 월별 급여 상세 정보
///
/// 특정 월의 급여 구성 항목 및 총액을 나타냄
class MonthlySalaryDetail extends Equatable {
  const MonthlySalaryDetail({
    required this.month,
    required this.baseSalary,
    required this.teachingAllowance,
    this.homeroomAllowance = 0,
    this.positionAllowance = 0,
    this.veteranAllowance = 0,
    required this.familyAllowance,
    required this.researchAllowance,
    this.mealAllowance = 0,
    this.overtimeAllowance = 0,
    this.longevityBonus = 0,
    required this.longevityMonthly,
    required this.grossSalary,
  });

  /// 월 (1~12)
  final int month;

  /// 본봉 (호봉에 따른 기본급)
  final int baseSalary;

  /// 교직수당 (25만원, 모든 교사)
  final int teachingAllowance;

  /// 담임수당 (20만원, 담임만)
  final int homeroomAllowance;

  /// 보직교사수당 (15만원, 보직교사만)
  final int positionAllowance;

  /// 원로교사수당 (5만원, 30년 이상 + 55세 이상)
  final int veteranAllowance;

  /// 가족수당 (배우자 4만 + 첫째 5만 + 둘째 8만 + 셋째이상 각12만)
  final int familyAllowance;

  /// 교원연구비 (7만원 5년 미만, 6만원 5년 이상)
  final int researchAllowance;

  /// 정액급식비 (14만원, 선택)
  final int mealAllowance;

  /// 시간외근무수당 정액분 (호봉별 12~16만원)
  final int overtimeAllowance;

  /// 정근수당 (1월/7월만, 월급의 10~50%)
  final int longevityBonus;

  /// 정근수당 가산금 (매월 3~13만원)
  final int longevityMonthly;

  /// 총 지급액
  final int grossSalary;

  /// 1월/7월 여부 (정근수당 지급 월)
  bool get hasLongevityBonus => month == 1 || month == 7;

  @override
  List<Object?> get props => [
    month,
    baseSalary,
    teachingAllowance,
    homeroomAllowance,
    positionAllowance,
    veteranAllowance,
    familyAllowance,
    researchAllowance,
    mealAllowance,
    overtimeAllowance,
    longevityBonus,
    longevityMonthly,
    grossSalary,
  ];

  MonthlySalaryDetail copyWith({
    int? month,
    int? baseSalary,
    int? teachingAllowance,
    int? homeroomAllowance,
    int? positionAllowance,
    int? veteranAllowance,
    int? familyAllowance,
    int? researchAllowance,
    int? mealAllowance,
    int? overtimeAllowance,
    int? longevityBonus,
    int? longevityMonthly,
    int? grossSalary,
  }) {
    return MonthlySalaryDetail(
      month: month ?? this.month,
      baseSalary: baseSalary ?? this.baseSalary,
      teachingAllowance: teachingAllowance ?? this.teachingAllowance,
      homeroomAllowance: homeroomAllowance ?? this.homeroomAllowance,
      positionAllowance: positionAllowance ?? this.positionAllowance,
      veteranAllowance: veteranAllowance ?? this.veteranAllowance,
      familyAllowance: familyAllowance ?? this.familyAllowance,
      researchAllowance: researchAllowance ?? this.researchAllowance,
      mealAllowance: mealAllowance ?? this.mealAllowance,
      overtimeAllowance: overtimeAllowance ?? this.overtimeAllowance,
      longevityBonus: longevityBonus ?? this.longevityBonus,
      longevityMonthly: longevityMonthly ?? this.longevityMonthly,
      grossSalary: grossSalary ?? this.grossSalary,
    );
  }
}
