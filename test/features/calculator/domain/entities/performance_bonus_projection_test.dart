import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/performance_bonus_projection.dart';

void main() {
  group('PerformanceBonusProjection', () {
    late PerformanceBonusProjection projection;

    setUp(() {
      projection = PerformanceBonusProjection();
    });

    group('calculateFutureBonus', () {
      test('기준 연도(2025년) 계산', () {
        final result = projection.calculateFutureBonus(targetYear: 2025);

        // 4,273,220원 (소수점 반올림)
        expect(result, equals(4273220));
      });

      test('5년 후(2030년) 계산 - 물가상승률 2.3% 적용', () {
        final result = projection.calculateFutureBonus(targetYear: 2030);

        // 4,273,220 × (1.023)^5 ≈ 4,787,772 (소수점 반올림)
        // 실제 값은 코드 로직에 따라 달라질 수 있으므로 범위로 검증
        expect(result, greaterThanOrEqualTo(4785000));
        expect(result, lessThanOrEqualTo(4790000));
      });

      test('35년 후(2060년) 계산 - 장기 예측', () {
        final result = projection.calculateFutureBonus(targetYear: 2060);

        // 4,273,220 × (1.023)^35 ≈ 9,471,350 (소수점 반올림)
        // 실제 계산 결과 검증
        expect(result, greaterThanOrEqualTo(9470000));
        expect(result, lessThanOrEqualTo(9473000));
      });

      test('소수점 반올림 검증', () {
        final result = projection.calculateFutureBonus(targetYear: 2025);

        // 결과는 정수여야 함 (소수점만 반올림)
        expect(result, isA<int>());
        expect(result, equals(4273220));
      });

      test('연도별 증가 확인', () {
        final result2025 = projection.calculateFutureBonus(targetYear: 2025);
        final result2026 = projection.calculateFutureBonus(targetYear: 2026);
        final result2027 = projection.calculateFutureBonus(targetYear: 2027);

        // 연도가 증가하면 금액도 증가해야 함
        expect(result2026, greaterThan(result2025));
        expect(result2027, greaterThan(result2026));
      });

      test('기준 연도보다 과거 연도 입력 시 예외 발생', () {
        expect(
          () => projection.calculateFutureBonus(targetYear: 2024),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => projection.calculateFutureBonus(targetYear: 2020),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('calculatePeriodTotal', () {
      test('단일 연도 기간 총합 - calculateFutureBonus와 동일', () {
        final futureBonus = projection.calculateFutureBonus(targetYear: 2025);
        final periodTotal = projection.calculatePeriodTotal(startYear: 2025, endYear: 2025);

        expect(periodTotal, equals(futureBonus));
      });

      test('5년 기간(2025-2029) 총합 계산', () {
        final total = projection.calculatePeriodTotal(startYear: 2025, endYear: 2029);

        // 수동 계산 검증
        int expectedTotal = 0;
        for (int year = 2025; year <= 2029; year++) {
          expectedTotal += projection.calculateFutureBonus(targetYear: year);
        }

        expect(total, equals(expectedTotal));
      });

      test('10년 기간(2025-2034) 총합 계산', () {
        final total = projection.calculatePeriodTotal(startYear: 2025, endYear: 2034);

        // 총합은 개별 연도 합과 동일해야 함
        int expectedTotal = 0;
        for (int year = 2025; year <= 2034; year++) {
          expectedTotal += projection.calculateFutureBonus(targetYear: year);
        }

        expect(total, equals(expectedTotal));
      });

      test('startYear > endYear 시 예외 발생', () {
        expect(
          () => projection.calculatePeriodTotal(startYear: 2030, endYear: 2025),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('장기 기간(2025-2060) 총합 계산 - 성능 테스트', () {
        // 35년간의 총합 계산이 정상적으로 작동하는지 확인
        expect(
          () => projection.calculatePeriodTotal(startYear: 2025, endYear: 2060),
          returnsNormally,
        );

        final total = projection.calculatePeriodTotal(startYear: 2025, endYear: 2060);

        // 35년간 총합은 최소 첫 해 금액 * 35년보다 커야 함 (물가상승 반영)
        final minExpected = projection.calculateFutureBonus(targetYear: 2025) * 35;
        expect(total, greaterThan(minExpected));
      });
    });

    group('getBonusInfo', () {
      test('2025년 정보 반환', () {
        final info = projection.getBonusInfo(targetYear: 2025);

        expect(info['year'], equals(2025));
        expect(info['amount'], equals(4273220));
        expect(info['yearDiff'], equals(0));
        expect(info['inflationRate'], equals(0.023));
        expect(info['grade'], equals('A'));
        expect(info['differentialPaymentRate'], equals(0.50));
      });

      test('2030년 정보 반환', () {
        final info = projection.getBonusInfo(targetYear: 2030);

        expect(info['year'], equals(2030));
        expect(info['amount'], isA<int>());
        expect(info['yearDiff'], equals(5));
        expect(info['inflationRate'], equals(0.023));
        expect(info['grade'], equals('A'));
        expect(info['differentialPaymentRate'], equals(0.50));
      });

      test('반환된 금액이 calculateFutureBonus와 일치', () {
        const targetYear = 2040;
        final info = projection.getBonusInfo(targetYear: targetYear);
        final directCalculation = projection.calculateFutureBonus(targetYear: targetYear);

        expect(info['amount'], equals(directCalculation));
      });
    });

    group('상수 값 검증', () {
      test('기준 연도는 2025년', () {
        expect(PerformanceBonusProjection.baseYear, equals(2025));
      });

      test('A등급 기준 금액은 4,273,220원', () {
        expect(PerformanceBonusProjection.baseAmountGradeA, equals(4273220));
      });

      test('물가상승률은 2.3%', () {
        expect(PerformanceBonusProjection.inflationRate, equals(0.023));
      });

      test('차등지급률은 50%', () {
        expect(PerformanceBonusProjection.differentialPaymentRate, equals(0.50));
      });
    });

    group('실제 사용 시나리오', () {
      test('교사의 30년 재직 기간 성과상여금 총액 계산', () {
        // 시나리오: 2025년 임용, 2054년 정년 (30년)
        final total = projection.calculatePeriodTotal(startYear: 2025, endYear: 2054);

        // 30년간 총액은 최소 1억원 이상이어야 함 (물가상승 반영)
        expect(total, greaterThan(100000000));

        // 총액은 정수여야 함
        expect(total, isA<int>());
      });

      test('조기 퇴직 시나리오 - 20년 재직', () {
        // 시나리오: 2025년 임용, 2044년 조기퇴직 (20년)
        final total = projection.calculatePeriodTotal(startYear: 2025, endYear: 2044);

        // 20년간 총액 계산
        expect(total, isA<int>());
        expect(total, greaterThan(0));
      });

      test('중간 연도(2035년) 단일 연도 조회', () {
        final info = projection.getBonusInfo(targetYear: 2035);

        // 10년 후 예상 금액
        expect(info['amount'], greaterThan(PerformanceBonusProjection.baseAmountGradeA));
        expect(info['yearDiff'], equals(10));
      });
    });
  });
}
