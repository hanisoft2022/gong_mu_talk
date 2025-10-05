import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/retirement_benefit_calculation_service.dart';

void main() {
  late RetirementBenefitCalculationService service;

  setUp(() {
    service = RetirementBenefitCalculationService();
  });

  group('RetirementBenefitCalculationService', () {
    group('calculateRetirementBenefit', () {
      test('1기간만 있는 경우 (2009년 이전 퇴직)', () {
        // Arrange
        final employmentStartDate = DateTime(2005, 3, 1);
        final retirementDate = DateTime(2009, 12, 31);
        const avgBaseIncome = 3000000;

        // Act
        final result = service.calculateRetirementBenefit(
          employmentStartDate: employmentStartDate,
          retirementDate: retirementDate,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result.period1Years, greaterThan(0));
        expect(result.period2Years, 0);
        expect(result.period3Years, 0);
        expect(result.period1Benefit, greaterThan(0));
        expect(result.period2Benefit, 0);
        expect(result.period3Benefit, 0);
        expect(result.totalBenefit, equals(result.period1Benefit));
        
        // 퇴직수당 = 1기간급여만 (2~3기간 없음)
        expect(result.retirementAllowance, equals(result.period1Benefit));
      });

      test('1~2기간이 있는 경우 (2010-2015년 퇴직)', () {
        // Arrange
        final employmentStartDate = DateTime(2005, 3, 1);
        final retirementDate = DateTime(2015, 12, 31);
        const avgBaseIncome = 3500000;

        // Act
        final result = service.calculateRetirementBenefit(
          employmentStartDate: employmentStartDate,
          retirementDate: retirementDate,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result.period1Years, greaterThan(0));
        expect(result.period2Years, greaterThan(0));
        expect(result.period3Years, 0);
        expect(result.period1Benefit, greaterThan(0));
        expect(result.period2Benefit, greaterThan(0));
        expect(result.period3Benefit, 0);
        
        // 총 퇴직급여 = 1기간 + 2기간
        expect(
          result.totalBenefit,
          equals(result.period1Benefit + result.period2Benefit),
        );
        
        // 퇴직수당 = 1기간 + (2기간 × 0.6)
        final expected2PeriodAllowance = (result.period2Benefit * 0.6).round();
        expect(
          result.retirementAllowance,
          equals(result.period1Benefit + expected2PeriodAllowance),
        );
      });

      test('1~3기간이 모두 있는 경우 (2016년 이후 퇴직)', () {
        // Arrange
        final employmentStartDate = DateTime(2005, 3, 1);
        final retirementDate = DateTime(2030, 2, 28);
        const avgBaseIncome = 4000000;

        // Act
        final result = service.calculateRetirementBenefit(
          employmentStartDate: employmentStartDate,
          retirementDate: retirementDate,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result.period1Years, greaterThan(0));
        expect(result.period2Years, greaterThan(0));
        expect(result.period3Years, greaterThan(0));
        expect(result.period1Benefit, greaterThan(0));
        expect(result.period2Benefit, greaterThan(0));
        expect(result.period3Benefit, greaterThan(0));
        
        // 총 퇴직급여 = 1기간 + 2기간 + 3기간
        expect(
          result.totalBenefit,
          equals(
            result.period1Benefit +
                result.period2Benefit +
                result.period3Benefit,
          ),
        );
        
        // 퇴직수당 = 1기간 + (2~3기간 × 0.6)
        final expected23PeriodAllowance = 
            ((result.period2Benefit + result.period3Benefit) * 0.6).round();
        expect(
          result.retirementAllowance,
          equals(result.period1Benefit + expected23PeriodAllowance),
        );
      });

      test('2016년 이후 입사 (3기간만)', () {
        // Arrange
        final employmentStartDate = DateTime(2020, 3, 1);
        final retirementDate = DateTime(2055, 2, 28);
        const avgBaseIncome = 3200000;

        // Act
        final result = service.calculateRetirementBenefit(
          employmentStartDate: employmentStartDate,
          retirementDate: retirementDate,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result.period1Years, 0);
        expect(result.period2Years, 0);
        expect(result.period3Years, greaterThan(0));
        expect(result.period1Benefit, 0);
        expect(result.period2Benefit, 0);
        expect(result.period3Benefit, greaterThan(0));
        expect(result.totalBenefit, equals(result.period3Benefit));
        
        // 퇴직수당 = (3기간 × 0.6)
        final expected3PeriodAllowance = (result.period3Benefit * 0.6).round();
        expect(result.retirementAllowance, equals(expected3PeriodAllowance));
      });

      test('평균 기준소득이 0인 경우', () {
        // Arrange
        final employmentStartDate = DateTime(2010, 3, 1);
        final retirementDate = DateTime(2040, 2, 28);
        const avgBaseIncome = 0;

        // Act
        final result = service.calculateRetirementBenefit(
          employmentStartDate: employmentStartDate,
          retirementDate: retirementDate,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result.totalBenefit, 0);
        expect(result.retirementAllowance, 0);
      });
    });

    group('calculateLumpSum', () {
      test('10년 미만 재직자는 일시금 수령', () {
        // Arrange
        const serviceYears = 8;
        const avgBaseIncome = 3000000;

        // Act
        final result = service.calculateLumpSum(
          serviceYears: serviceYears,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result, greaterThan(0));
        // 일시금 = 평균 기준소득월액 × 재직월수 × 9%
        final expected = (avgBaseIncome * serviceYears * 12 * 0.09).toInt();
        expect(result, equals(expected));
      });

      test('10년 이상 재직자는 일시금 없음', () {
        // Arrange
        const serviceYears = 15;
        const avgBaseIncome = 4000000;

        // Act
        final result = service.calculateLumpSum(
          serviceYears: serviceYears,
          avgBaseIncome: avgBaseIncome,
        );

        // Assert
        expect(result, 0);
      });
    });
  });
}
