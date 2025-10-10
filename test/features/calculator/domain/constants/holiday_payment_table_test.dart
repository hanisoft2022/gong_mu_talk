import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/holiday_payment_table.dart';

void main() {
  group('HolidayPaymentTable', () {
    group('getPaymentMonths', () {
      test('2025년 명절 지급 월 조회', () {
        // Given
        final months = HolidayPaymentTable.getPaymentMonths(2025);

        // Then
        expect(months, isNotNull);
        expect(months!.lunarNewYear, 1); // 설날 1/29 → 1월
        expect(months.chuseok, 10); // 추석 10/3 → 10월
      });

      test('2030년 명절 지급 월 조회', () {
        // Given
        final months = HolidayPaymentTable.getPaymentMonths(2030);

        // Then
        expect(months, isNotNull);
        expect(months!.lunarNewYear, 2); // 설날 2/3 → 2월
        expect(months.chuseok, 9); // 추석 9/12 → 9월
      });

      test('2050년 명절 지급 월 조회', () {
        // Given
        final months = HolidayPaymentTable.getPaymentMonths(2050);

        // Then
        expect(months, isNotNull);
        expect(months!.lunarNewYear, 1); // 설날 1/23 → 1월
        expect(months.chuseok, 9); // 추석 9/29 → 9월
      });

      test('2073년 명절 지급 월 조회 (마지막 연도)', () {
        // Given
        final months = HolidayPaymentTable.getPaymentMonths(2073);

        // Then
        expect(months, isNotNull);
        expect(months!.lunarNewYear, 2); // 설날 2/7 → 2월
        expect(months.chuseok, 9); // 추석 9/15 → 9월
      });

      test('데이터 없는 연도 조회 시 null 반환', () {
        // Given
        final months2024 = HolidayPaymentTable.getPaymentMonths(2024);
        final months2074 = HolidayPaymentTable.getPaymentMonths(2074);

        // Then
        expect(months2024, isNull);
        expect(months2074, isNull);
      });
    });

    group('hasHolidayBonus', () {
      test('2025년 1월에 명절상여금 지급 (설날)', () {
        // When
        final hasBonus = HolidayPaymentTable.hasHolidayBonus(2025, 1);

        // Then
        expect(hasBonus, isTrue);
      });

      test('2025년 10월에 명절상여금 지급 (추석)', () {
        // When
        final hasBonus = HolidayPaymentTable.hasHolidayBonus(2025, 10);

        // Then
        expect(hasBonus, isTrue);
      });

      test('2025년 5월에 명절상여금 없음', () {
        // When
        final hasBonus = HolidayPaymentTable.hasHolidayBonus(2025, 5);

        // Then
        expect(hasBonus, isFalse);
      });

      test('2026년 2월에 명절상여금 지급 (설날)', () {
        // When
        final hasBonus = HolidayPaymentTable.hasHolidayBonus(2026, 2);

        // Then
        expect(hasBonus, isTrue);
      });

      test('2026년 9월에 명절상여금 지급 (추석)', () {
        // When
        final hasBonus = HolidayPaymentTable.hasHolidayBonus(2026, 9);

        // Then
        expect(hasBonus, isTrue);
      });
    });

    group('calculateHolidayBonus', () {
      test('명절 월에 본봉의 60% 지급', () {
        // Given
        const baseSalary = 2500000;

        // When: 2025년 1월 (설날)
        final bonus = HolidayPaymentTable.calculateHolidayBonus(
          baseSalary: baseSalary,
          year: 2025,
          month: 1,
        );

        // Then: 2,500,000 × 0.6 = 1,500,000원
        expect(bonus, 1500000);
      });

      test('일반 월에는 0원 지급', () {
        // Given
        const baseSalary = 2500000;

        // When: 2025년 5월 (일반 월)
        final bonus = HolidayPaymentTable.calculateHolidayBonus(
          baseSalary: baseSalary,
          year: 2025,
          month: 5,
        );

        // Then: 0원
        expect(bonus, 0);
      });

      test('본봉이 다를 때 정확한 계산', () {
        // Given: 9호봉 본봉
        const baseSalary = 2792000;

        // When: 2025년 10월 (추석)
        final bonus = HolidayPaymentTable.calculateHolidayBonus(
          baseSalary: baseSalary,
          year: 2025,
          month: 10,
        );

        // Then: 2,792,000 × 0.6 = 1,675,200원
        expect(bonus, 1675200);
      });
    });

    group('calculateAnnualHolidayBonus', () {
      test('연간 명절상여금 총액 = 본봉 × 1.2', () {
        // Given
        const baseSalary = 2500000;

        // When
        final annualBonus = HolidayPaymentTable.calculateAnnualHolidayBonus(
          baseSalary: baseSalary,
          year: 2025,
        );

        // Then: 2,500,000 × 1.2 = 3,000,000원 (설날 + 추석)
        expect(annualBonus, 3000000);
      });

      test('9호봉 연간 명절상여금 총액', () {
        // Given: 9호봉 본봉
        const baseSalary = 2792000;

        // When
        final annualBonus = HolidayPaymentTable.calculateAnnualHolidayBonus(
          baseSalary: baseSalary,
          year: 2025,
        );

        // Then: 2,792,000 × 1.2 = 3,350,400원
        expect(annualBonus, 3350400);
      });

      test('데이터 없는 연도는 0원 반환', () {
        // Given
        const baseSalary = 2500000;

        // When
        final annualBonus = HolidayPaymentTable.calculateAnnualHolidayBonus(
          baseSalary: baseSalary,
          year: 2074,
        );

        // Then
        expect(annualBonus, 0);
      });
    });

    group('isDataAvailable', () {
      test('2025년 데이터 제공', () {
        expect(HolidayPaymentTable.isDataAvailable(2025), isTrue);
      });

      test('2073년 데이터 제공', () {
        expect(HolidayPaymentTable.isDataAvailable(2073), isTrue);
      });

      test('2024년 데이터 미제공', () {
        expect(HolidayPaymentTable.isDataAvailable(2024), isFalse);
      });

      test('2074년 데이터 미제공', () {
        expect(HolidayPaymentTable.isDataAvailable(2074), isFalse);
      });

      test('2050년 데이터 제공 (중간 연도)', () {
        expect(HolidayPaymentTable.isDataAvailable(2050), isTrue);
      });
    });

    group('데이터 범위 상수', () {
      test('최소/최대 연도 확인', () {
        expect(HolidayPaymentTable.minYear, 2025);
        expect(HolidayPaymentTable.maxYear, 2073);
      });

      test('제공 기간은 49년', () {
        const years = HolidayPaymentTable.maxYear - HolidayPaymentTable.minYear + 1;
        expect(years, 49);
      });
    });

    group('실제 사용 시나리오', () {
      test('24세 입직 교사의 정년(62세)까지 모든 연도 데이터 존재', () {
        // Given: 2025년에 24세로 입직
        const startYear = 2025;
        const startAge = 24;
        const retirementAge = 62;
        const endYear = startYear + (retirementAge - startAge); // 2063년

        // When: 재직 기간의 모든 연도 확인
        for (int year = startYear; year <= endYear; year++) {
          final isAvailable = HolidayPaymentTable.isDataAvailable(year);

          // Then: 모든 연도 데이터 제공
          expect(isAvailable, isTrue, reason: '$year년 데이터가 없습니다 (24세 입직자의 정년까지 필요)');
        }
      });

      test('설날과 추석은 각각 1~2월, 9~10월에만 발생', () {
        // Given: 2025~2073년 전체
        for (int year = HolidayPaymentTable.minYear; year <= HolidayPaymentTable.maxYear; year++) {
          final months = HolidayPaymentTable.getPaymentMonths(year);

          // Then: 설날은 1~2월, 추석은 9~10월
          expect(
            months!.lunarNewYear,
            inInclusiveRange(1, 2),
            reason: '$year년 설날이 잘못된 월($months.lunarNewYear)',
          );
          expect(
            months.chuseok,
            inInclusiveRange(9, 10),
            reason: '$year년 추석이 잘못된 월($months.chuseok)',
          );
        }
      });
    });
  });
}
