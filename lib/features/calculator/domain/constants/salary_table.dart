/// 2025년 기준 교원 호봉별 본봉표 (단위: 원)
/// 출처: 공무원 보수규정
class SalaryTable {
  static const Map<int, int> teacherBasePay = {
    1: 1934100,
    2: 2056800,
    3: 2184200,
    4: 2316400,
    5: 2453500,
    6: 2595600,
    7: 2742800,
    8: 2895200,
    9: 3052900,
    10: 3216000,
    11: 3384600,
    12: 3558800,
    13: 3738700,
    14: 3924400,
    15: 4116000,
    16: 4313600,
    17: 4517300,
    18: 4727200,
    19: 4943400,
    20: 5166000,
    21: 5395100,
    22: 5630900,
    23: 5873500,
    24: 6123000,
    25: 6379500,
    26: 6643100,
    27: 6913900,
    28: 7192000,
    29: 7477500,
    30: 7770500,
    31: 8071100,
    32: 8379400,
    33: 8695500,
    34: 9019500,
    35: 9351500,
    36: 9691600,
    37: 10040000,
    38: 10396800,
    39: 10762100,
    40: 11136000,
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
