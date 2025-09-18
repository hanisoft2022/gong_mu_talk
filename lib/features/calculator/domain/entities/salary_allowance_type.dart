enum SalaryAllowanceType {
  replacement,
  nightDuty,
  hazard,
}

extension SalaryAllowanceTypeX on SalaryAllowanceType {
  String get label {
    switch (this) {
      case SalaryAllowanceType.replacement:
        return '보결 수당';
      case SalaryAllowanceType.nightDuty:
        return '야간 수당';
      case SalaryAllowanceType.hazard:
        return '위험 수당';
    }
  }

  String get key => name;
}
