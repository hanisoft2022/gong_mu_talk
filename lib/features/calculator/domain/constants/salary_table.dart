/// 2025년 기준 교원 호봉별 본봉표 (단위: 원)
/// 출처: 공무원 보수규정
class SalaryTable {
  static const Map<int, int> teacherBasePay = {
    1: 1915100,
    2: 1973100,
    3: 2031900,
    4: 2090500,
    5: 2149600,
    6: 2208600,
    7: 2267000,
    8: 2325100,
    9: 2365500,
    10: 2387800,
    11: 2408300,
    12: 2455700,
    13: 2567600,
    14: 2679900,
    15: 2792000,
    16: 2904500,
    17: 3015500,
    18: 3131900,
    19: 3247500,
    20: 3363300,
    21: 3478900,
    22: 3607300,
    23: 3734600,
    24: 3862300,
    25: 3989800,
    26: 4117800,
    27: 4251300,
    28: 4384500,
    29: 4523800,
    30: 4663600,
    31: 4803000,
    32: 4942200,
    33: 5083700,
    34: 5224600,
    35: 5365800,
    36: 5506400,
    37: 5628700,
    38: 5751200,
    39: 5873900,
    40: 5995800,
  };

  /// 호봉별 본봉 조회
  static int getBasePay(int grade) {
    return teacherBasePay[grade] ?? 0;
  }

  /// 교감 본봉표 (교사 + 직급보조비)
  static int getVicePrincipalPay(int grade) {
    final basePay = getBasePay(grade);
    const positionSupplement = 300000; // 교감 직급보조비
    return basePay + positionSupplement;
  }

  /// 교장 본봉표 (교사 + 직급보조비)
  static int getPrincipalPay(int grade) {
    final basePay = getBasePay(grade);
    const positionSupplement = 500000; // 교장 직급보조비
    return basePay + positionSupplement;
  }
}

/// 수당 기준표 (2025년 기준)
class AllowanceTable {
  /// 교직수당 (모든 교사)
  static const int teachingAllowance = 250000;

  // ========== 교직수당 가산금 (10가지) ==========

  /// 가산금 1: 원로교사수당 (30년 이상 재직 + 55세 이상)
  static const int allowance1VeteranTeacher = 50000;

  /// 가산금 2: 보직교사수당 (부장 등)
  static const int allowance2HeadTeacher = 150000;

  /// 가산금 3: 특수교사수당
  static const int allowance3SpecialEducation = 120000;

  /// 가산금 4: 담임수당
  static const int allowance4Homeroom = 200000;

  /// 가산금 5: 특성화교사수당 (호봉별 차등)
  static const int allowance5VocationalMin = 25000; // 1~4호봉
  static const int allowance5VocationalMax = 50000; // 31~40호봉

  /// 가산금 6: 보건교사수당 (2025년 1만원 인상)
  static const int allowance6HealthTeacher = 40000;

  /// 가산금 7: 겸직수당 (병설유치원 겸임)
  static const int allowance7ConcurrentPrincipal = 100000; // 교장
  static const int allowance7ConcurrentVice = 50000; // 교감

  /// 가산금 8: 영양교사수당 (2025년 1만원 인상)
  static const int allowance8Nutrition = 40000;

  /// 가산금 9: 사서교사수당 (2025년 1만원 인상)
  static const int allowance9Librarian = 30000;

  /// 가산금 10: 전문상담교사수당 (2025년 1만원 인상)
  static const int allowance10Counselor = 30000;

  // ========== 기존 호환성을 위한 별칭 (Deprecated) ==========

  /// @deprecated Use allowance4Homeroom instead
  static const int homeroomAllowance = allowance4Homeroom;

  /// @deprecated Use allowance2HeadTeacher instead
  static const int headTeacherAllowance = allowance2HeadTeacher;

  /// @deprecated Use allowance1VeteranTeacher instead
  static const int veteranAllowance = allowance1VeteranTeacher;

  // ========== 기타 수당 ==========

  /// 교감 관리수당
  static const int vicePrincipalManagementAllowance = 300000;

  /// 교장 관리수당
  static const int principalManagementAllowance = 450000;

  /// 가족수당 (1인당, 참고용 - 실제 계산은 SalaryCalculationService 사용)
  static const int familyAllowancePerPerson = 40000;

  /// 정액급식비
  static const int mealAllowance = 140000;

  /// 시간외근무수당 정액분 (호봉별, 2025년 기준)
  /// 시간당 단가 × 10시간 = 월 정액분
  static const Map<int, int> overtimeAllowanceByGrade = {
    19: 123130, // 1~19호봉: 12,313원/시간 × 10
    29: 137330, // 20~29호봉: 13,733원/시간 × 10
    40: 147410, // 30호봉 이상: 14,741원/시간 × 10
  };

  /// 호봉별 시간외근무수당(정액분) 조회
  static int getOvertimeAllowance(int grade) {
    if (grade <= 19) return overtimeAllowanceByGrade[19]!;
    if (grade <= 29) return overtimeAllowanceByGrade[29]!;
    return overtimeAllowanceByGrade[40]!;
  }
}
