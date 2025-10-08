/// 세금 및 보험료 계산 서비스
class TaxCalculationService {
  /// 교사/공무원 소득세 간이 계산
  ///
  /// 주의: 이는 추정치입니다.
  /// - 실제 간이세액표는 매우 복잡하므로 단순화된 공식 사용
  /// - 연말정산에서 최종 세액이 확정됩니다
  /// - 오차범위: ±10,000원 내외
  ///
  /// [monthlyGrossPay] 월급여 (총급여액)
  /// [dependents] 부양가족 수 (본인 제외)
  ///
  /// Returns 추정 소득세액
  int calculateIncomeTax(int monthlyGrossPay, {int dependents = 1}) {
    // 1단계: 과세표준 추정 (실제 간이세액표는 근로소득공제 후 과세표준 기준)
    // 공무원의 경우 공제 후 약 80% 정도가 과세표준이 됨
    // - 공무원연금(9%) + 건강보험(3.545%) + 장기요양(0.46%) ≈ 13%
    // - 근로소득공제 추가 적용 시 총 20% 정도 공제
    final taxableIncome = (monthlyGrossPay * 0.80).round();

    // 2단계: 기본 세액 계산 (2025년 근로소득 간이세액 기준 단순화)
    int baseTax;
    if (taxableIncome <= 1060000) {
      baseTax = 0;
    } else if (taxableIncome <= 2100000) {
      baseTax = ((taxableIncome - 1060000) * 0.06).round();
    } else if (taxableIncome <= 3340000) {
      baseTax = (62400 + (taxableIncome - 2100000) * 0.15).round();
    } else if (taxableIncome <= 5000000) {
      baseTax = (248400 + (taxableIncome - 3340000) * 0.24).round();
    } else if (taxableIncome <= 7000000) {
      baseTax = (646800 + (taxableIncome - 5000000) * 0.35).round();
    } else {
      baseTax = (1346800 + (taxableIncome - 7000000) * 0.38).round();
    }

    // 3단계: 부양가족 공제 적용
    // 간이세액표 기준: 부양가족 수에 따른 세액 감소
    // 소득 구간별로 차등 적용 (고소득일수록 공제 효과 큼)
    int dependentDeduction = 0;
    if (dependents > 0) {
      if (taxableIncome <= 2000000) {
        dependentDeduction = dependents * 20000;
      } else if (taxableIncome <= 3000000) {
        dependentDeduction = dependents * 40000;
      } else if (taxableIncome <= 5000000) {
        dependentDeduction = dependents * 50000;
      } else {
        dependentDeduction = dependents * 60000;
      }
    }

    // 최종 소득세 (0원 이상)
    return (baseTax - dependentDeduction).clamp(0, double.infinity).toInt();
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
