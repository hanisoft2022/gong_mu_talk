/// 공무원 수당 종류
enum SalaryAllowanceType {
  /// 정액급식비
  mealAllowance,
  
  /// 교통보조비
  transportationAllowance,
  
  /// 시간외근무수당
  overtimeAllowance,
  
  /// 직급보조비
  positionAllowance,
  
  /// 가족수당
  familyAllowance,
  
  /// 보육수당
  childcareAllowance,
  
  /// 주택수당
  housingAllowance,
  
  /// 특수업무수당 (구 위험수당)
  specialDutyAllowance,
  
  /// 야간근무수당
  nightDutyAllowance,
  
  /// 명절휴가비
  holidayAllowance,
  
  /// 정근수당 (근속가산금)
  longevityAllowance,
  
  /// 성과상여금
  performanceBonus,
  
  /// 기타 수당
  other,
}

extension SalaryAllowanceTypeX on SalaryAllowanceType {
  String get label {
    switch (this) {
      case SalaryAllowanceType.mealAllowance:
        return '정액급식비';
      case SalaryAllowanceType.transportationAllowance:
        return '교통보조비';
      case SalaryAllowanceType.overtimeAllowance:
        return '시간외근무수당';
      case SalaryAllowanceType.positionAllowance:
        return '직급보조비';
      case SalaryAllowanceType.familyAllowance:
        return '가족수당';
      case SalaryAllowanceType.childcareAllowance:
        return '보육수당';
      case SalaryAllowanceType.housingAllowance:
        return '주택수당';
      case SalaryAllowanceType.specialDutyAllowance:
        return '특수업무수당';
      case SalaryAllowanceType.nightDutyAllowance:
        return '야간근무수당';
      case SalaryAllowanceType.holidayAllowance:
        return '명절휴가비';
      case SalaryAllowanceType.longevityAllowance:
        return '정근수당';
      case SalaryAllowanceType.performanceBonus:
        return '성과상여금';
      case SalaryAllowanceType.other:
        return '기타 수당';
    }
  }

  String get key => name;
  
  /// 수당 설명
  String get description {
    switch (this) {
      case SalaryAllowanceType.mealAllowance:
        return '월 130,000원 (2025년 기준)';
      case SalaryAllowanceType.transportationAllowance:
        return '월 200,000원 (2025년 기준)';
      case SalaryAllowanceType.overtimeAllowance:
        return '시간외 근무 시간에 따라 지급';
      case SalaryAllowanceType.positionAllowance:
        return '직급에 따라 차등 지급';
      case SalaryAllowanceType.familyAllowance:
        return '배우자 40,000원, 자녀 1인당 20,000원';
      case SalaryAllowanceType.childcareAllowance:
        return '만 6세 이하 자녀 1인당 100,000원';
      case SalaryAllowanceType.housingAllowance:
        return '무주택자 기준 월 최대 300,000원';
      case SalaryAllowanceType.specialDutyAllowance:
        return '특수업무 종사자에게 지급';
      case SalaryAllowanceType.nightDutyAllowance:
        return '야간 근무 시간에 따라 지급';
      case SalaryAllowanceType.holidayAllowance:
        return '설, 추석 등 명절 전 지급';
      case SalaryAllowanceType.longevityAllowance:
        return '근속연수에 따라 지급';
      case SalaryAllowanceType.performanceBonus:
        return '개인 및 조직 성과에 따라 지급';
      case SalaryAllowanceType.other:
        return '기타 법정 또는 임의 수당';
    }
  }
  
  /// 일반적인 지급 빈도
  PaymentFrequency get frequency {
    switch (this) {
      case SalaryAllowanceType.mealAllowance:
      case SalaryAllowanceType.transportationAllowance:
      case SalaryAllowanceType.overtimeAllowance:
      case SalaryAllowanceType.positionAllowance:
      case SalaryAllowanceType.familyAllowance:
      case SalaryAllowanceType.childcareAllowance:
      case SalaryAllowanceType.housingAllowance:
      case SalaryAllowanceType.specialDutyAllowance:
      case SalaryAllowanceType.nightDutyAllowance:
        return PaymentFrequency.monthly;
      case SalaryAllowanceType.holidayAllowance:
      case SalaryAllowanceType.longevityAllowance:
        return PaymentFrequency.biannual;
      case SalaryAllowanceType.performanceBonus:
        return PaymentFrequency.annual;
      case SalaryAllowanceType.other:
        return PaymentFrequency.variable;
    }
  }
}

/// 수당 지급 빈도
enum PaymentFrequency {
  /// 매월 지급
  monthly,
  
  /// 반기별 지급 (년 2회)
  biannual,
  
  /// 연간 지급 (년 1회)
  annual,
  
  /// 가변적
  variable,
}
