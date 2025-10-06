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

  /// 담임수당
  static const int homeroomAllowance = 200000;

  /// 보직교사수당 (부장 등)
  static const int headTeacherAllowance = 150000;

  /// 원로교사수당 (30년 이상 재직 + 55세 이상)
  static const int veteranAllowance = 50000;

  /// 교감 관리수당
  static const int vicePrincipalManagementAllowance = 300000;

  /// 교장 관리수당
  static const int principalManagementAllowance = 450000;

  /// 가족수당 (1인당, 참고용 - 실제 계산은 SalaryCalculationService 사용)
  static const int familyAllowancePerPerson = 40000;

  /// 정액급식비
  static const int mealAllowance = 140000;

  /// 시간외근무수당 정액분 (호봉별)
  static const Map<int, int> overtimeAllowanceByGrade = {
    10: 120000, // 1~10호봉
    20: 140000, // 11~20호봉
    40: 160000, // 21호봉 이상
  };

  /// 호봉별 시간외근무수당 조회
  static int getOvertimeAllowance(int grade) {
    if (grade <= 10) return overtimeAllowanceByGrade[10]!;
    if (grade <= 20) return overtimeAllowanceByGrade[20]!;
    return overtimeAllowanceByGrade[40]!;
  }
}
