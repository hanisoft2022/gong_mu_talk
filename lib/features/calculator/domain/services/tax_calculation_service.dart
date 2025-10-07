/// 세금 및 보험료 계산 서비스
class TaxCalculationService {
  /// 소득세 계산 (간이세액표 기준)
  int calculateIncomeTax(int monthlyGrossPay, {int dependents = 1}) {
    // 2025년 근로소득 간이세액표 기준 (간략화)
    // 실제로는 더 복잡한 구간별 계산이 필요하지만, MVP에서는 단순화

    if (monthlyGrossPay <= 1060000) return 0;
    if (monthlyGrossPay <= 2100000) {
      return ((monthlyGrossPay - 1060000) * 0.06).round();
    }
    if (monthlyGrossPay <= 3340000) {
      return (62400 + (monthlyGrossPay - 2100000) * 0.15).round();
    }
    if (monthlyGrossPay <= 7000000) {
      return (248400 + (monthlyGrossPay - 3340000) * 0.24).round();
    }
    if (monthlyGrossPay <= 12000000) {
      return (1126800 + (monthlyGrossPay - 7000000) * 0.35).round();
    }

    return (2876800 + (monthlyGrossPay - 12000000) * 0.38).round();
  }

  /// 지방소득세 계산 (소득세의 10%)
  int calculateLocalIncomeTax(int incomeTax) {
    return (incomeTax * 0.1).round();
  }

  /// 국민연금 계산 (기준소득월액의 4.5%)
  int calculateNationalPension(int baseIncome) {
    // 상한액: 617만원, 하한액: 39만원
    final cappedIncome = baseIncome.clamp(390000, 6170000);
    return (cappedIncome * 0.045).round();
  }

  /// 건강보험 계산 (보수월액의 3.545%)
  int calculateHealthInsurance(int monthlyPay) {
    return (monthlyPay * 0.03545).round();
  }

  /// 장기요양보험 계산 (건강보험료의 12.95%)
  int calculateLongTermCareInsurance(int healthInsurance) {
    return (healthInsurance * 0.1295).round();
  }

  /// 고용보험 계산 (보수월액의 0.9%)
  int calculateEmploymentInsurance(int monthlyPay) {
    return (monthlyPay * 0.009).round();
  }

  /// 4대보험 합계 계산
  int calculateTotalInsurance(int monthlyGrossPay) {
    final nationalPension = calculateNationalPension(monthlyGrossPay);
    final healthInsurance = calculateHealthInsurance(monthlyGrossPay);
    final longTermCare = calculateLongTermCareInsurance(healthInsurance);
    final employment = calculateEmploymentInsurance(monthlyGrossPay);

    return nationalPension + healthInsurance + longTermCare + employment;
  }

  /// 총 공제액 계산 (세금 + 4대보험)
  int calculateTotalDeductions(int monthlyGrossPay, {int dependents = 1}) {
    final incomeTax = calculateIncomeTax(
      monthlyGrossPay,
      dependents: dependents,
    );
    final localIncomeTax = calculateLocalIncomeTax(incomeTax);
    final insurance = calculateTotalInsurance(monthlyGrossPay);

    return incomeTax + localIncomeTax + insurance;
  }

  /// 실수령액 계산
  int calculateNetPay(int monthlyGrossPay, {int dependents = 1}) {
    final deductions = calculateTotalDeductions(
      monthlyGrossPay,
      dependents: dependents,
    );
    return monthlyGrossPay - deductions;
  }
}
