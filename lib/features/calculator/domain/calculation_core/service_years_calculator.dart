import 'package:equatable/equatable.dart';

/// 재직 년수 및 기간 정보
///
/// 일수 기반으로 정확하게 계산된 재직 기간 정보
class ServiceYearsInfo extends Equatable {
  /// 만 년수 (정수)
  final int fullYears;

  /// 나머지 월수 (0-11)
  final int remainingMonths;

  /// 총 일수
  final int totalDays;

  /// 시작일
  final DateTime startDate;

  /// 종료일
  final DateTime endDate;

  const ServiceYearsInfo({
    required this.fullYears,
    required this.remainingMonths,
    required this.totalDays,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [
        fullYears,
        remainingMonths,
        totalDays,
        startDate,
        endDate,
      ];

  @override
  String toString() {
    return 'ServiceYearsInfo('
        'fullYears: $fullYears, '
        'remainingMonths: $remainingMonths, '
        'totalDays: $totalDays, '
        'startDate: ${startDate.toLocal()}, '
        'endDate: ${endDate.toLocal()}'
        ')';
  }
}

/// 재직년수 통합 계산기 (Single Source of Truth)
///
/// 이 클래스는 프로젝트 전체에서 재직년수를 계산하는 유일한 진입점입니다.
/// 모든 서비스는 이 클래스를 통해 재직년수를 계산해야 합니다.
///
/// 계산 방식:
/// - 일수 기반 정확 계산 (365일 = 1년)
/// - 만 나이 방식 적용
///
/// 사용 예:
/// ```dart
/// final serviceInfo = ServiceYearsCalculator.calculate(
///   DateTime(2020, 3, 15),
///   DateTime(2025, 3, 14),
/// );
/// print(serviceInfo.fullYears); // 4 (만 4년)
/// ```
class ServiceYearsCalculator {
  ServiceYearsCalculator._(); // Private constructor to prevent instantiation

  /// 재직 기간 계산 (일수 기반 정확 계산)
  ///
  /// [startDate] 임용일 또는 시작일
  /// [endDate] 종료일 (현재일 또는 퇴직일)
  ///
  /// Returns: 재직 년수 및 상세 정보
  ///
  /// 계산 방식:
  /// - totalDays = endDate - startDate
  /// - fullYears = floor(totalDays / 365)
  /// - remainingMonths = floor((totalDays % 365) / 30)
  static ServiceYearsInfo calculate(DateTime startDate, DateTime endDate) {
    // 시작일이 종료일보다 나중이면 0 반환
    if (startDate.isAfter(endDate)) {
      return ServiceYearsInfo(
        fullYears: 0,
        remainingMonths: 0,
        totalDays: 0,
        startDate: startDate,
        endDate: endDate,
      );
    }

    final totalDays = endDate.difference(startDate).inDays;
    final fullYears = (totalDays / 365).floor();
    final remainingDays = totalDays % 365;
    final remainingMonths = (remainingDays / 30).floor();

    return ServiceYearsInfo(
      fullYears: fullYears,
      remainingMonths: remainingMonths,
      totalDays: totalDays,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 만 나이 계산 (생일 정확히 고려)
  ///
  /// [birthYear] 출생 년도
  /// [birthMonth] 출생 월 (1-12)
  /// [targetDate] 기준일 (나이를 계산할 날짜)
  ///
  /// Returns: 만 나이
  ///
  /// 계산 방식:
  /// - 기준일이 생일 이전이면 나이에서 1을 뺌
  /// - 생일 당일부터 만 나이 증가
  ///
  /// 예시:
  /// - 1990년 3월생, 2025년 2월 기준 → 34세
  /// - 1990년 3월생, 2025년 3월 기준 → 35세
  static int calculateAge(
    int birthYear,
    int birthMonth,
    DateTime targetDate,
  ) {
    int age = targetDate.year - birthYear;

    // 아직 생일이 지나지 않았으면 -1
    if (targetDate.month < birthMonth ||
        (targetDate.month == birthMonth && targetDate.day < 1)) {
      age--;
    }

    return age;
  }

  /// 특정 날짜의 재직 년수 계산 (편의 메서드)
  ///
  /// [startDate] 임용일
  /// [targetYear] 계산할 년도
  /// [targetMonth] 계산할 월 (기본값: 1월)
  ///
  /// Returns: 해당 시점의 만 년수
  static int getFullYearsAt(
    DateTime startDate,
    int targetYear, {
    int targetMonth = 1,
  }) {
    final targetDate = DateTime(targetYear, targetMonth, 1);
    final serviceInfo = calculate(startDate, targetDate);
    return serviceInfo.fullYears;
  }
}
