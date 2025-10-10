import 'package:equatable/equatable.dart';

/// 명절상여금 지급 월 정보
///
/// 설날과 추석이 속한 월에 명절상여금(본봉의 60%)이 지급됨
class HolidayPaymentMonths extends Equatable {
  /// 설날 지급 월 (1~2월)
  final int lunarNewYear;

  /// 추석 지급 월 (9~10월)
  final int chuseok;

  const HolidayPaymentMonths({required this.lunarNewYear, required this.chuseok});

  @override
  List<Object> get props => [lunarNewYear, chuseok];
}

/// 명절상여금 지급 월 테이블 (2025~2073년, 49년치)
///
/// **Single Source of Truth** for 명절상여금 계산
///
/// 데이터 출처:
/// - 한국천문연구원 음력-양력 변환 데이터
/// - 나무위키 설날/추석 연도별 날짜
///
/// 계산 규칙:
/// - 명절상여금 = 본봉 × 60%
/// - 지급 시기: 명절이 속한 월의 급여에 포함
/// - 예: 설날 1월 29일 → 1월 급여, 추석 10월 3일 → 10월 급여
///
/// ⚠️ 업데이트 필요 시점: **2033년**
/// - 2074-2075년 데이터 추가 필요 (24세 입직자가 62세 정년 시 필요)
/// - 업데이트 시 한국천문연구원 또는 공공데이터 참조
///
/// 사용 예:
/// ```dart
/// final months = HolidayPaymentTable.getPaymentMonths(2025);
/// if (months != null && months.lunarNewYear == currentMonth) {
///   final bonus = baseSalary * 0.6;
/// }
/// ```
class HolidayPaymentTable {
  HolidayPaymentTable._(); // Private constructor to prevent instantiation

  /// 연도별 명절상여금 지급 월 맵 (2025~2073년)
  ///
  /// Key: 연도 (year)
  /// Value: HolidayPaymentMonths (설날/추석 지급 월)
  static const Map<int, HolidayPaymentMonths> _paymentMonths = {
    // 2025-2030
    2025: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/29, 추석 10/3
    2026: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/17, 추석 9/24
    2027: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/7, 추석 9/15
    2028: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/27, 추석 9/30
    2029: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/13, 추석 9/22
    2030: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/3, 추석 9/12
    // 2031-2040
    2031: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/23, 추석 10/1
    2032: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/11, 추석 9/19
    2033: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/31, 추석 9/8
    2034: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/19, 추석 9/26
    2035: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/8, 추석 9/15
    2036: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/28, 추석 10/4
    2037: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/15, 추석 9/23
    2038: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/4, 추석 9/11
    2039: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/24, 추석 10/1
    2040: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/12, 추석 9/20
    // 2041-2050
    2041: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/1, 추석 9/7
    2042: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/22, 추석 9/27
    2043: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/10, 추석 9/16
    2044: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/30, 추석 10/1
    2045: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/17, 추석 9/23
    2046: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/6, 추석 9/14
    2047: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/26, 추석 10/3
    2048: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/14, 추석 9/19
    2049: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/2, 추석 9/10
    2050: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/23, 추석 9/29
    // 2051-2060
    2051: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/10, 추석 9/16
    2052: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/31, 추석 9/7
    2053: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/15, 추석 9/25
    2054: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/7, 추석 9/12
    2055: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/27, 추석 10/2
    2056: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/12, 추석 9/23
    2057: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/3, 추석 9/12
    2058: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/23, 추석 9/28
    2059: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/8, 추석 9/20
    2060: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/31, 추석 9/8
    // 2061-2070
    2061: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/22, 추석 9/28
    2062: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/9, 추석 9/17
    2063: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/29, 추석 10/6
    2064: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/17, 추석 9/25
    2065: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/5, 추석 9/15
    2066: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10), // 설날 1/26, 추석 10/5
    2067: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/14, 추석 9/23
    2068: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/3, 추석 9/11
    2069: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/23, 추석 9/29
    2070: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/11, 추석 9/19
    // 2071-2073
    2071: HolidayPaymentMonths(lunarNewYear: 1, chuseok: 9), // 설날 1/31, 추석 9/8
    2072: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/19, 추석 9/26
    2073: HolidayPaymentMonths(lunarNewYear: 2, chuseok: 9), // 설날 2/7, 추석 9/15
    // ⚠️ !TODO (2033년 업데이트 필요):
    // 2074: 설날 1/27, 추석 미정
    // 2075: 설날 2/15, 추석 미정
  };

  /// 특정 연도의 명절상여금 지급 월 조회
  ///
  /// [year] 연도
  ///
  /// Returns: 명절상여금 지급 월 정보, 데이터가 없으면 null
  ///
  /// 예시:
  /// ```dart
  /// final months = HolidayPaymentTable.getPaymentMonths(2025);
  /// // HolidayPaymentMonths(lunarNewYear: 1, chuseok: 10)
  /// ```
  static HolidayPaymentMonths? getPaymentMonths(int year) {
    return _paymentMonths[year];
  }

  /// 특정 연도/월에 명절상여금 지급 여부 확인
  ///
  /// [year] 연도
  /// [month] 월 (1~12)
  ///
  /// Returns: 해당 월에 명절상여금 지급 여부
  ///
  /// 예시:
  /// ```dart
  /// final hasBonus = HolidayPaymentTable.hasHolidayBonus(2025, 1); // true (설날)
  /// final hasBonus = HolidayPaymentTable.hasHolidayBonus(2025, 5); // false
  /// ```
  static bool hasHolidayBonus(int year, int month) {
    final months = _paymentMonths[year];
    if (months == null) return false;
    return months.lunarNewYear == month || months.chuseok == month;
  }

  /// 명절상여금 금액 계산
  ///
  /// [baseSalary] 본봉
  /// [year] 연도
  /// [month] 월 (1~12)
  ///
  /// Returns: 명절상여금 (해당 월에 지급 시 본봉 × 60%, 아니면 0)
  ///
  /// 예시:
  /// ```dart
  /// final bonus = HolidayPaymentTable.calculateHolidayBonus(
  ///   baseSalary: 2500000,
  ///   year: 2025,
  ///   month: 1, // 설날
  /// ); // 1500000원
  /// ```
  static int calculateHolidayBonus({
    required int baseSalary,
    required int year,
    required int month,
  }) {
    if (hasHolidayBonus(year, month)) {
      return (baseSalary * 0.6).round();
    }
    return 0;
  }

  /// 연간 명절상여금 총액 계산 (설날 + 추석)
  ///
  /// [baseSalary] 본봉
  /// [year] 연도
  ///
  /// Returns: 연간 명절상여금 총액 (본봉 × 1.2)
  ///
  /// 예시:
  /// ```dart
  /// final annualBonus = HolidayPaymentTable.calculateAnnualHolidayBonus(
  ///   baseSalary: 2500000,
  ///   year: 2025,
  /// ); // 3000000원 (1500000 × 2)
  /// ```
  static int calculateAnnualHolidayBonus({required int baseSalary, required int year}) {
    final months = _paymentMonths[year];
    if (months == null) return 0;

    // 설날 + 추석 = 본봉 × 60% × 2 = 본봉 × 1.2
    return (baseSalary * 1.2).round();
  }

  /// 데이터 제공 연도 범위
  static const int minYear = 2025;
  static const int maxYear = 2073;

  /// 데이터 제공 여부 확인
  ///
  /// [year] 연도
  ///
  /// Returns: 해당 연도 데이터 제공 여부
  static bool isDataAvailable(int year) {
    return year >= minYear && year <= maxYear;
  }
}
