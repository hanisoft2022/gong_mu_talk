import 'package:gong_mu_talk/features/calculator/domain/entities/base_income_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';

/// 기준소득월액 추정 서비스
class BaseIncomeEstimationService {
  /// 기준소득월액 추정
  ///
  /// [baseSalary] 기본급
  /// [allowances] 수당 정보
  /// [serviceYears] 재직 년수
  /// [currentGrade] 현재 호봉
  ///
  /// Returns: 기준소득월액 추정 정보
  BaseIncomeEstimate estimateBaseIncome({
    required int baseSalary,
    required Allowance allowances,
    required int serviceYears,
    required int currentGrade,
  }) {
    // 1. 총 급여 계산 (세전)
    final grossIncome = baseSalary +
        allowances.homeroom +
        allowances.headTeacher +
        allowances.family +
        allowances.veteran +
        allowances.other1 +
        allowances.other2;

    // 2. 제외 항목 계산
    // 성과급 (연 1회, 월 환산)
    final performanceBonus = _estimatePerformanceBonus(baseSalary);
    final excludedPerformance = (performanceBonus / 12).round();

    // 시간외근무수당 (정액 + 초과)
    final overtimeAllowance = _estimateOvertimeAllowance(currentGrade);
    final excludedOvertime = overtimeAllowance;

    // 연구비
    final researchAllowance = _estimateResearchAllowance(serviceYears);
    final excludedResearch = researchAllowance;

    // 식대보조비 (정액급식비)
    const mealAllowance = 140000;
    final excludedMeal = mealAllowance;

    // 3. 포함 항목 계산 (평균액)
    // 성과급 평균액 (3년 평균 가정)
    final includedAvgPerformance = (excludedPerformance * 0.8).round();

    // 시간외 평균액 (실제 수령액의 80% 가정)
    final includedAvgOvertime = (excludedOvertime * 0.8).round();

    // 연가보상 평균액 (연 1회, 월 환산)
    final yearEndBonus = _estimateYearEndBonus(serviceYears);
    final includedYearEndBonus = (yearEndBonus / 12).round();

    // 4. 최종 기준소득월액 계산
    // = 총 급여 - 제외 항목 + 포함 항목
    final baseIncome = grossIncome -
        excludedPerformance -
        excludedOvertime -
        excludedResearch -
        excludedMeal +
        includedAvgPerformance +
        includedAvgOvertime +
        includedYearEndBonus;

    return BaseIncomeEstimate(
      grossIncome: grossIncome,
      excludedPerformance: excludedPerformance,
      excludedOvertime: excludedOvertime,
      excludedResearch: excludedResearch,
      excludedMeal: excludedMeal,
      includedAvgPerformance: includedAvgPerformance,
      includedAvgOvertime: includedAvgOvertime,
      includedYearEndBonus: includedYearEndBonus,
      baseIncome: baseIncome,
    );
  }

  /// 성과급 추정 (연 1회)
  ///
  /// [baseSalary] 기본급
  ///
  /// Returns: 연간 성과급
  int _estimatePerformanceBonus(int baseSalary) {
    // 성과급 = 기본급 × 성과율 (평균 200% 가정)
    return (baseSalary * 2.0).round();
  }

  /// 시간외근무수당 추정
  ///
  /// [currentGrade] 현재 호봉
  ///
  /// Returns: 월 시간외근무수당
  int _estimateOvertimeAllowance(int currentGrade) {
    // 호봉별 정액분
    if (currentGrade <= 10) return 120000;
    if (currentGrade <= 20) return 140000;
    return 160000;
  }

  /// 연구비 추정
  ///
  /// [serviceYears] 재직 년수
  ///
  /// Returns: 월 연구비
  int _estimateResearchAllowance(int serviceYears) {
    // 5년 미만: 7만원, 5년 이상: 6만원
    return serviceYears < 5 ? 70000 : 60000;
  }

  /// 연가보상 추정 (연 1회)
  ///
  /// [serviceYears] 재직 년수
  ///
  /// Returns: 연간 연가보상금
  int _estimateYearEndBonus(int serviceYears) {
    // 재직년수별 연가보상 (평균 50만원 가정)
    if (serviceYears < 5) return 300000;
    if (serviceYears < 10) return 400000;
    if (serviceYears < 20) return 500000;
    return 600000;
  }

  /// 연도별 기준소득월액 추정 (평생)
  ///
  /// [currentBaseSalary] 현재 기본급
  /// [currentAllowances] 현재 수당
  /// [currentServiceYears] 현재 재직 년수
  /// [currentGrade] 현재 호봉
  /// [targetYears] 목표 년수
  /// [salaryIncreaseRate] 급여 인상률 (연)
  ///
  /// Returns: 연도별 기준소득월액 목록
  List<Map<String, dynamic>> estimateLifetimeBaseIncome({
    required int currentBaseSalary,
    required Allowance currentAllowances,
    required int currentServiceYears,
    required int currentGrade,
    required int targetYears,
    double salaryIncreaseRate = 0.025,
  }) {
    final results = <Map<String, dynamic>>[];

    int baseSalary = currentBaseSalary;
    int serviceYears = currentServiceYears;
    int grade = currentGrade;

    for (int year = 0; year < targetYears; year++) {
      final estimate = estimateBaseIncome(
        baseSalary: baseSalary,
        allowances: currentAllowances,
        serviceYears: serviceYears,
        currentGrade: grade,
      );

      results.add({
        'year': year,
        'serviceYears': serviceYears,
        'grade': grade,
        'baseSalary': baseSalary,
        'baseIncome': estimate.baseIncome,
        'estimate': estimate,
      });

      // 다음 년도 계산
      baseSalary = (baseSalary * (1 + salaryIncreaseRate)).round();
      serviceYears++;
      grade++;
    }

    return results;
  }

  /// 평균 기준소득월액 계산
  ///
  /// [lifetimeEstimates] 연도별 기준소득월액 목록
  ///
  /// Returns: 평균 기준소득월액
  int calculateAverageBaseIncome(
    List<Map<String, dynamic>> lifetimeEstimates,
  ) {
    if (lifetimeEstimates.isEmpty) return 0;

    final total = lifetimeEstimates.fold<int>(
      0,
      (sum, item) => sum + (item['baseIncome'] as int),
    );

    return (total / lifetimeEstimates.length).round();
  }
}
