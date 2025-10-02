/// 소득세 및 지방소득세 계산 서비스
library;

import 'package:injectable/injectable.dart';

/// 2025년 기준 소득세법 적용
@lazySingleton
class TaxCalculator {
  /// 2025년 소득세 과세표준 및 세율
  /// 출처: 소득세법 제55조
  static const List<TaxBracket> _taxBrackets = [
    TaxBracket(limit: 14000000, rate: 0.06, deduction: 0),
    TaxBracket(limit: 50000000, rate: 0.15, deduction: 1260000),
    TaxBracket(limit: 88000000, rate: 0.24, deduction: 5760000),
    TaxBracket(limit: 150000000, rate: 0.35, deduction: 15440000),
    TaxBracket(limit: 300000000, rate: 0.38, deduction: 19940000),
    TaxBracket(limit: 500000000, rate: 0.40, deduction: 25940000),
    TaxBracket(limit: 1000000000, rate: 0.42, deduction: 35940000),
    TaxBracket(limit: double.infinity, rate: 0.45, deduction: 65940000),
  ];

  /// 연간 소득세 계산 (누진공제 방식)
  /// 
  /// [annualIncome]: 연간 과세표준 (총급여 - 소득공제)
  /// Returns: 연간 소득세액
  double calculateAnnualIncomeTax(double annualIncome) {
    if (annualIncome <= 0) return 0;

    for (final bracket in _taxBrackets) {
      if (annualIncome <= bracket.limit) {
        final tax = annualIncome * bracket.rate - bracket.deduction;
        return tax > 0 ? tax : 0;
      }
    }

    // Should never reach here due to infinity limit
    return 0;
  }

  /// 월 소득세 계산 (간이세액표 방식)
  /// 
  /// 실무에서는 간이세액표를 사용하나, 여기서는 단순화를 위해
  /// 연간 예상소득을 12로 나눈 근사값 사용
  /// 
  /// [monthlyGross]: 월 총급여
  /// [dependents]: 부양가족 수 (본인 포함)
  /// Returns: 월 원천징수 소득세
  double calculateMonthlyIncomeTax({
    required double monthlyGross,
    int dependents = 1,
  }) {
    // 연간 총급여 추정
    final double annualGross = monthlyGross * 12;

    // 근로소득공제 적용 (간이 계산)
    final double annualDeduction = _calculateEmploymentIncomeDeduction(annualGross);
    final double taxableIncome = annualGross - annualDeduction;

    // 연간 소득세 계산 후 12개월 분할
    final double annualTax = calculateAnnualIncomeTax(taxableIncome);
    double monthlyTax = annualTax / 12;

    // 부양가족 수에 따른 세액 감면 (간소화)
    // 실제로는 복잡한 인적공제 적용
    if (dependents > 1) {
      final reductionRate = ((dependents - 1) * 0.05).clamp(0.0, 0.3);
      monthlyTax *= (1 - reductionRate);
    }

    return monthlyTax > 0 ? monthlyTax : 0;
  }

  /// 근로소득공제 계산
  /// 출처: 소득세법 제47조
  double _calculateEmploymentIncomeDeduction(double annualGross) {
    if (annualGross <= 5000000) {
      return annualGross * 0.70;
    } else if (annualGross <= 15000000) {
      return 3500000 + (annualGross - 5000000) * 0.40;
    } else if (annualGross <= 45000000) {
      return 7500000 + (annualGross - 15000000) * 0.15;
    } else if (annualGross <= 100000000) {
      return 12000000 + (annualGross - 45000000) * 0.05;
    } else {
      return 14750000 + (annualGross - 100000000) * 0.02;
    }
  }

  /// 지방소득세 계산
  /// 소득세의 10%
  double calculateLocalIncomeTax(double incomeTax) {
    return incomeTax * 0.10;
  }

  /// 총 세금 계산 (소득세 + 지방소득세)
  TaxBreakdown calculateTotalTax({
    required double monthlyGross,
    int dependents = 1,
  }) {
    final incomeTax = calculateMonthlyIncomeTax(
      monthlyGross: monthlyGross,
      dependents: dependents,
    );
    final localTax = calculateLocalIncomeTax(incomeTax);

    return TaxBreakdown(
      incomeTax: incomeTax,
      localIncomeTax: localTax,
      totalTax: incomeTax + localTax,
    );
  }
}

/// 세율 구간
class TaxBracket {
  const TaxBracket({
    required this.limit,
    required this.rate,
    required this.deduction,
  });

  final double limit;      // 과세표준 상한
  final double rate;       // 세율
  final double deduction;  // 누진공제액
}

/// 세금 계산 결과
class TaxBreakdown {
  const TaxBreakdown({
    required this.incomeTax,
    required this.localIncomeTax,
    required this.totalTax,
  });

  final double incomeTax;       // 소득세
  final double localIncomeTax;  // 지방소득세
  final double totalTax;        // 합계

  @override
  String toString() {
    return 'TaxBreakdown(incomeTax: $incomeTax, localTax: $localIncomeTax, total: $totalTax)';
  }
}
