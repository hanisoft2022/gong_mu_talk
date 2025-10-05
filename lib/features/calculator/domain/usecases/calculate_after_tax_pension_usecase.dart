import 'package:gong_mu_talk/features/calculator/domain/entities/after_tax_pension.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/pension_calculation_service.dart';

/// 세후 연금 계산 UseCase
class CalculateAfterTaxPensionUseCase {
  final PensionCalculationService _service;

  CalculateAfterTaxPensionUseCase(this._service);

  /// 세후 연금 계산 실행
  ///
  /// [pensionEstimate] 세전 연금 정보
  /// [age] 수령 시점 연령 (선택)
  ///
  /// Returns: 세후 연금 정보
  AfterTaxPension call({
    required PensionEstimate pensionEstimate,
    int? age,
  }) {
    return _service.calculateAfterTaxPension(
      pensionEstimate: pensionEstimate,
      age: age,
    );
  }

  /// 연령별 세후 연금 비교
  ///
  /// [pensionEstimate] 세전 연금 정보
  /// [startAge] 시작 연령
  /// [endAge] 종료 연령
  ///
  /// Returns: 연령별 세후 연금 목록
  List<AfterTaxPension> compareByAge({
    required PensionEstimate pensionEstimate,
    int startAge = 60,
    int endAge = 85,
  }) {
    final results = <AfterTaxPension>[];

    for (int age = startAge; age <= endAge; age++) {
      final afterTaxPension = _service.calculateAfterTaxPension(
        pensionEstimate: pensionEstimate,
        age: age,
      );
      results.add(afterTaxPension);
    }

    return results;
  }

  /// 평생 세후 연금 총액 계산
  ///
  /// [pensionEstimate] 세전 연금 정보
  /// [retirementAge] 퇴직 연령
  /// [lifeExpectancy] 기대수명
  ///
  /// Returns: 평생 세후 연금 총액
  int calculateLifetimeAfterTaxPension({
    required PensionEstimate pensionEstimate,
    required int retirementAge,
    int lifeExpectancy = 85,
  }) {
    int total = 0;

    for (int age = retirementAge; age < lifeExpectancy; age++) {
      final afterTaxPension = _service.calculateAfterTaxPension(
        pensionEstimate: pensionEstimate,
        age: age,
      );
      total += afterTaxPension.annualPensionAfterTax;
    }

    return total;
  }

  /// 세전 vs 세후 비교
  ///
  /// [pensionEstimate] 세전 연금 정보
  /// [age] 수령 시점 연령
  ///
  /// Returns: {beforeTax, afterTax, taxAmount, taxRate}
  Map<String, dynamic> compareBeforeAndAfterTax({
    required PensionEstimate pensionEstimate,
    int? age,
  }) {
    final afterTaxPension = _service.calculateAfterTaxPension(
      pensionEstimate: pensionEstimate,
      age: age,
    );

    final monthlyBeforeTax = pensionEstimate.monthlyPension;
    final monthlyAfterTax = afterTaxPension.monthlyPensionAfterTax;
    final taxAmount = afterTaxPension.totalDeductions;
    final taxRate = afterTaxPension.deductionRate;

    return {
      'beforeTax': monthlyBeforeTax,
      'afterTax': monthlyAfterTax,
      'taxAmount': taxAmount,
      'taxRate': taxRate,
    };
  }
}
