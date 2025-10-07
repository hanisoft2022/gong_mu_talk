import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';

/// 명예퇴직금 계산 서비스
class EarlyRetirementCalculationService {
  /// 명예퇴직금 계산
  ///
  /// [profile] 교사 프로필
  /// [earlyRetirementDate] 명퇴 예정일 (선택, 없으면 현재 기준)
  ///
  /// Returns: 명예퇴직금 정보
  EarlyRetirementBonus calculateEarlyRetirementBonus({
    required TeacherProfile profile,
    DateTime? earlyRetirementDate,
  }) {
    final retirementDate = earlyRetirementDate ?? DateTime.now();

    // 1. 정년퇴직일 계산
    final regularRetirementDate = profile.calculateRetirementDate();

    // 2. 잔여 기간 계산 (명퇴일 ~ 정년퇴직일)
    final remainingDays = regularRetirementDate
        .difference(retirementDate)
        .inDays;
    final remainingYears = (remainingDays / 365).floor();
    final remainingMonths = ((remainingDays % 365) / 30).floor();

    // 3. 기본급 조회 (명퇴 시점 호봉 기준)
    final currentGrade = profile.currentGrade;
    final baseSalary = SalaryTable.getBasePay(currentGrade);

    // 4. 명퇴 시점 연령 계산
    final retirementAge = retirementDate.year - profile.birthYear;

    // 5. 기본 명퇴금 계산
    // 기본 명퇴금 = 기본급 × 잔여 년수 × 계수
    final baseCoefficient = _getBaseCoefficient(remainingYears);
    final baseAmount = (baseSalary * remainingYears * baseCoefficient).toInt();

    // 6. 가산금 계산
    // 가산금 = 기본급 × 잔여 년수 × 가산율
    final bonusRate = _getBonusRate(remainingYears, retirementAge);
    final bonusAmount = (baseSalary * remainingYears * bonusRate).toInt();

    // 7. 총액
    final totalAmount = baseAmount + bonusAmount;

    return EarlyRetirementBonus(
      baseAmount: baseAmount,
      bonusAmount: bonusAmount,
      totalAmount: totalAmount,
      remainingYears: remainingYears,
      remainingMonths: remainingMonths,
      retirementAge: retirementAge,
      baseSalary: baseSalary,
      currentGrade: currentGrade,
    );
  }

  /// 명퇴 시기별 금액 비교
  ///
  /// [profile] 교사 프로필
  /// [startAge] 시작 연령 (기본: 50세)
  /// [endAge] 종료 연령 (기본: 정년-1)
  ///
  /// Returns: 연령별 명퇴금 목록
  List<EarlyRetirementBonus> compareEarlyRetirementScenarios({
    required TeacherProfile profile,
    int? startAge,
    int? endAge,
  }) {
    final scenarios = <EarlyRetirementBonus>[];

    final currentAge = DateTime.now().year - profile.birthYear;
    final startRetirementAge = startAge ?? 50;
    final endRetirementAge = endAge ?? (profile.retirementAge - 1);

    for (int age = startRetirementAge; age <= endRetirementAge; age++) {
      // 현재 나이보다 이전은 스킵
      if (age < currentAge) continue;

      // 해당 연령 시점의 날짜 계산
      final retirementDate = DateTime(
        profile.birthYear + age,
        profile.birthMonth,
        1,
      );

      final bonus = calculateEarlyRetirementBonus(
        profile: profile,
        earlyRetirementDate: retirementDate,
      );

      scenarios.add(bonus);
    }

    return scenarios;
  }

  /// 기본 명퇴금 계수 계산
  ///
  /// [remainingYears] 잔여 년수
  ///
  /// Returns: 기본 계수 (0.5 ~ 1.5)
  double _getBaseCoefficient(int remainingYears) {
    // 잔여 년수에 따른 기본 계수
    if (remainingYears >= 10) return 1.5;
    if (remainingYears >= 7) return 1.3;
    if (remainingYears >= 5) return 1.1;
    if (remainingYears >= 3) return 0.9;
    if (remainingYears >= 1) return 0.7;
    return 0.5;
  }

  /// 가산율 계산
  ///
  /// [remainingYears] 잔여 년수
  /// [retirementAge] 명퇴 연령
  ///
  /// Returns: 가산율 (0.0 ~ 0.5)
  double _getBonusRate(int remainingYears, int retirementAge) {
    // 기본 가산율 (잔여 년수 기준)
    double baseRate = 0.0;
    if (remainingYears >= 10) {
      baseRate = 0.4;
    } else if (remainingYears >= 7) {
      baseRate = 0.3;
    } else if (remainingYears >= 5) {
      baseRate = 0.2;
    } else if (remainingYears >= 3) {
      baseRate = 0.1;
    }

    // 연령 가산 (55세 이상 +0.1)
    if (retirementAge >= 55) {
      baseRate += 0.1;
    }

    return baseRate;
  }

  /// 명퇴금 월별 적립액 계산
  ///
  /// [totalAmount] 총 명퇴금
  /// [remainingMonths] 잔여 개월수
  ///
  /// Returns: 월별 적립액
  int calculateMonthlyAccumulation({
    required int totalAmount,
    required int remainingMonths,
  }) {
    if (remainingMonths == 0) return 0;
    return (totalAmount / remainingMonths).round();
  }

  /// 명퇴 vs 정년 총 수령액 비교
  ///
  /// [earlyRetirementBonus] 명퇴금
  /// [earlyRetirementPension] 명퇴 시 연금 (월)
  /// [regularRetirementPension] 정년 시 연금 (월)
  /// [remainingYears] 잔여 년수
  /// [lifeExpectancy] 기대수명
  ///
  /// Returns: {earlyTotal, regularTotal, difference}
  Map<String, int> compareEarlyVsRegularRetirement({
    required int earlyRetirementBonus,
    required int earlyRetirementPension,
    required int regularRetirementPension,
    required int remainingYears,
    required int retirementAge,
    int lifeExpectancy = 85,
  }) {
    // 1. 명퇴 시 총 수령액
    // = 명퇴금 + (명퇴 연금 × 12개월 × 수령년수)
    final earlyPensionYears = lifeExpectancy - retirementAge;
    final earlyTotal =
        earlyRetirementBonus +
        (earlyRetirementPension * 12 * earlyPensionYears);

    // 2. 정년 시 총 수령액
    // = (정년까지 급여 × 잔여년수) + (정년 연금 × 12개월 × 수령년수)
    final regularRetirementAge = retirementAge + remainingYears;
    final regularPensionYears = lifeExpectancy - regularRetirementAge;
    final estimatedMonthlySalary = earlyRetirementPension; // 간략화: 연금액과 동일하게 가정
    final regularTotal =
        (estimatedMonthlySalary * 12 * remainingYears) +
        (regularRetirementPension * 12 * regularPensionYears);

    final difference = earlyTotal - regularTotal;

    return {
      'earlyTotal': earlyTotal,
      'regularTotal': regularTotal,
      'difference': difference,
    };
  }
}
