import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/calculation_core/service_years_calculator.dart';

void main() {
  group('ServiceYearsCalculator', () {
    group('calculate', () {
      test('정확한 재직년수 계산 - 생일 하루 전', () {
        // Given: 2020.3.15 입직, 2025.3.14 기준
        final result = ServiceYearsCalculator.calculate(
          DateTime(2020, 3, 15),
          DateTime(2025, 3, 14),
        );

        // Then: 1825일 = 5년 (365 * 5 = 1825)
        expect(result.fullYears, 5);
        expect(result.remainingMonths, 0);
        expect(result.totalDays, 1825);
      });

      test('정확한 재직년수 계산 - 생일 당일', () {
        // Given: 2020.3.15 입직, 2025.3.15 기준
        final result = ServiceYearsCalculator.calculate(
          DateTime(2020, 3, 15),
          DateTime(2025, 3, 15),
        );

        // Then: 만 5년 정확히
        expect(result.fullYears, 5);
        expect(result.remainingMonths, 0);
        expect(result.totalDays, 1826); // 5년치 일수
      });

      test('1년 미만 재직', () {
        // Given: 2024.3.1 입직, 2024.12.31 기준
        final result = ServiceYearsCalculator.calculate(
          DateTime(2024, 3, 1),
          DateTime(2024, 12, 31),
        );

        // Then: 0년
        expect(result.fullYears, 0);
        expect(result.remainingMonths, greaterThanOrEqualTo(9));
        expect(result.totalDays, 305); // 3월 1일 ~ 12월 31일
      });

      test('정확히 10년', () {
        // Given: 2015.1.1 입직, 2025.1.1 기준
        final result = ServiceYearsCalculator.calculate(
          DateTime(2015, 1, 1),
          DateTime(2025, 1, 1),
        );

        // Then: 정확히 10년
        expect(result.fullYears, 10);
        expect(result.remainingMonths, 0);
      });

      test('37년 재직 (초임~정년)', () {
        // Given: 25세 입직, 62세 정년 (37년)
        final result = ServiceYearsCalculator.calculate(
          DateTime(1988, 3, 1),
          DateTime(2025, 3, 1),
        );

        // Then: 37년
        expect(result.fullYears, 37);
      });

      test('시작일이 종료일보다 나중인 경우', () {
        // Given: 잘못된 날짜 (종료일이 시작일보다 이전)
        final result = ServiceYearsCalculator.calculate(
          DateTime(2025, 1, 1),
          DateTime(2020, 1, 1),
        );

        // Then: 모두 0
        expect(result.fullYears, 0);
        expect(result.remainingMonths, 0);
        expect(result.totalDays, 0);
      });

      test('동일한 날짜', () {
        // Given: 시작일과 종료일이 동일
        final result = ServiceYearsCalculator.calculate(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 1),
        );

        // Then: 모두 0
        expect(result.fullYears, 0);
        expect(result.remainingMonths, 0);
        expect(result.totalDays, 0);
      });
    });

    group('calculateAge', () {
      test('만 나이 계산 - 생일 이전', () {
        // Given: 1990년 3월생, 2025년 2월 기준
        final age = ServiceYearsCalculator.calculateAge(
          1990,
          3,
          DateTime(2025, 2, 1),
        );

        // Then: 34세 (아직 생일 안 지남)
        expect(age, 34);
      });

      test('만 나이 계산 - 생일 당일', () {
        // Given: 1990년 3월생, 2025년 3월 1일 기준
        final age = ServiceYearsCalculator.calculateAge(
          1990,
          3,
          DateTime(2025, 3, 1),
        );

        // Then: 35세 (생일 지남)
        expect(age, 35);
      });

      test('만 나이 계산 - 생일 이후', () {
        // Given: 1990년 3월생, 2025년 4월 기준
        final age = ServiceYearsCalculator.calculateAge(
          1990,
          3,
          DateTime(2025, 4, 1),
        );

        // Then: 35세
        expect(age, 35);
      });

      test('만 나이 계산 - 1살', () {
        // Given: 2024년생, 2025년 기준
        final age = ServiceYearsCalculator.calculateAge(
          2024,
          1,
          DateTime(2025, 2, 1),
        );

        // Then: 1세
        expect(age, 1);
      });

      test('만 나이 계산 - 0살 (생일 전)', () {
        // Given: 2025년 1월생, 2025년 1월 1일 기준 (생일 전)
        final age = ServiceYearsCalculator.calculateAge(
          2025,
          2,
          DateTime(2025, 1, 1),
        );

        // Then: 0세
        expect(age, -1); // 아직 태어나지 않음
      });

      test('55세 이상 (원로교사수당 조건)', () {
        // Given: 1970년생, 2025년 기준
        final age = ServiceYearsCalculator.calculateAge(
          1970,
          1,
          DateTime(2025, 6, 1),
        );

        // Then: 55세
        expect(age, 55);
        expect(age, greaterThanOrEqualTo(55));
      });
    });

    group('getFullYearsAt', () {
      test('특정 연도의 재직년수 계산', () {
        // Given: 2020.3.15 입직
        final years = ServiceYearsCalculator.getFullYearsAt(
          DateTime(2020, 3, 15),
          2025,
        );

        // Then: 2025년 1월 1일 기준 약 4년
        expect(years, 4);
      });

      test('입직 첫 해', () {
        // Given: 2025.3.1 입직, 2025년 기준
        final years = ServiceYearsCalculator.getFullYearsAt(
          DateTime(2025, 3, 1),
          2025,
        );

        // Then: 0년 (아직 1년 안 됨)
        expect(years, 0);
      });

      test('targetMonth 지정', () {
        // Given: 2020.3.15 입직, 2025년 6월 기준
        final years = ServiceYearsCalculator.getFullYearsAt(
          DateTime(2020, 3, 15),
          2025,
          targetMonth: 6,
        );

        // Then: 2025년 6월 기준 5년
        expect(years, 5);
      });
    });

    group('ServiceYearsInfo', () {
      test('toString 출력 형식', () {
        // Given
        final info = ServiceYearsInfo(
          fullYears: 5,
          remainingMonths: 3,
          totalDays: 1920,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2025, 4, 1),
        );

        // Then: toString이 정상 동작
        final str = info.toString();
        expect(str, contains('fullYears: 5'));
        expect(str, contains('remainingMonths: 3'));
        expect(str, contains('totalDays: 1920'));
      });

      test('Equatable props', () {
        // Given: 동일한 값을 가진 두 객체
        final info1 = ServiceYearsInfo(
          fullYears: 5,
          remainingMonths: 3,
          totalDays: 1920,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2025, 4, 1),
        );

        final info2 = ServiceYearsInfo(
          fullYears: 5,
          remainingMonths: 3,
          totalDays: 1920,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2025, 4, 1),
        );

        // Then: 동일한 객체로 간주
        expect(info1, equals(info2));
      });
    });
  });
}
