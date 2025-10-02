import 'package:equatable/equatable.dart';

/// 공무원연금 프로필
/// 개인의 연금 수급 정보
class PensionProfile extends Equatable {
  const PensionProfile({
    required this.birthYear,
    required this.appointmentYear,
    required this.retirementYear,
    required this.averageMonthlyIncome,
    required this.totalServiceYears,
    this.expectedLifespan = 85,
    this.inflationRate = 0.02,
  });

  /// 출생연도
  final int birthYear;

  /// 임용연도
  final int appointmentYear;

  /// 퇴직연도
  final int retirementYear;

  /// 평균 기준소득월액
  /// 전체 재직기간의 기준소득월액 평균
  final double averageMonthlyIncome;

  /// 총 재직기간 (년)
  final int totalServiceYears;

  /// 예상 수명
  final int expectedLifespan;

  /// 물가상승률
  final double inflationRate;

  /// 현재 나이
  int get currentAge {
    final currentYear = DateTime.now().year;
    return currentYear - birthYear;
  }

  /// 퇴직 시 나이
  int get retirementAge => retirementYear - birthYear;

  /// 연금 수급 시작 연령
  /// 조기퇴직이 아니면 퇴직 시 바로 시작
  int get pensionStartAge => retirementAge;

  /// 연금 수급 기간 (년)
  int get pensionDuration {
    final duration = expectedLifespan - pensionStartAge;
    return duration > 0 ? duration : 0;
  }

  /// 법정 정년 (공무원: 60세)
  static const int statutoryRetirementAge = 60;

  /// 조기퇴직 여부
  bool get isEarlyRetirement => retirementAge < statutoryRetirementAge;

  /// 조기퇴직 연수
  int get earlyRetirementYears {
    if (!isEarlyRetirement) return 0;
    return statutoryRetirementAge - retirementAge;
  }

  PensionProfile copyWith({
    int? birthYear,
    int? appointmentYear,
    int? retirementYear,
    double? averageMonthlyIncome,
    int? totalServiceYears,
    int? expectedLifespan,
    double? inflationRate,
  }) {
    return PensionProfile(
      birthYear: birthYear ?? this.birthYear,
      appointmentYear: appointmentYear ?? this.appointmentYear,
      retirementYear: retirementYear ?? this.retirementYear,
      averageMonthlyIncome: averageMonthlyIncome ?? this.averageMonthlyIncome,
      totalServiceYears: totalServiceYears ?? this.totalServiceYears,
      expectedLifespan: expectedLifespan ?? this.expectedLifespan,
      inflationRate: inflationRate ?? this.inflationRate,
    );
  }

  @override
  List<Object?> get props => [
        birthYear,
        appointmentYear,
        retirementYear,
        averageMonthlyIncome,
        totalServiceYears,
        expectedLifespan,
        inflationRate,
      ];
}
