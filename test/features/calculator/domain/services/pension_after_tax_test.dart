import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/pension_calculation_service.dart';

void main() {
  late PensionCalculationService service;

  setUp(() {
    service = PensionCalculationService();
  });

  group('PensionCalculationService - After Tax', () {
    group('calculateAfterTaxPension', () {
      test('70세 미만 - 기본 공제 500만원', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 2000000,
          annualPension: 26000000,
          totalPension: 520000000,
          retirementAge: 65,
          lifeExpectancy: 85,
          serviceYears: 30,
          avgBaseIncome: 4000000,
          pensionRate: 0.68,
          totalContribution: 129600000,
          transitionRate: 0.98,
          redistributionRate: 0.90,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
          age: 65,
        );

        // Assert
        expect(result.monthlyPensionBeforeTax, 2000000);
        expect(result.incomeTax, greaterThan(0));
        expect(result.localTax, equals((result.incomeTax * 0.1).round()));
        expect(result.healthInsurance, greaterThan(0));
        expect(result.longTermCareInsurance, greaterThan(0));
      });

      test('70-79세 - 공제 700만원', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 2500000,
          annualPension: 32500000,
          totalPension: 325000000,
          retirementAge: 75,
          lifeExpectancy: 85,
          serviceYears: 35,
          avgBaseIncome: 4500000,
          pensionRate: 0.76,
          totalContribution: 170100000,
          transitionRate: 0.98,
          redistributionRate: 0.88,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
          age: 75,
        );

        // Assert
        expect(result.incomeTax, greaterThan(0));
        expect(result.localTax, equals((result.incomeTax * 0.1).round()));
      });

      test('80세 이상 - 공제 1000만원', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 3000000,
          annualPension: 39000000,
          totalPension: 195000000,
          retirementAge: 85,
          lifeExpectancy: 90,
          serviceYears: 35,
          avgBaseIncome: 5000000,
          pensionRate: 0.76,
          totalContribution: 189000000,
          transitionRate: 0.98,
          redistributionRate: 0.86,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
          age: 85,
        );

        // Assert
        expect(result.incomeTax, greaterThan(0));
        expect(result.localTax, equals((result.incomeTax * 0.1).round()));
      });

      test('건강보험료 6.99%', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 2200000,
          annualPension: 28600000,
          totalPension: 572000000,
          retirementAge: 66,
          lifeExpectancy: 86,
          serviceYears: 32,
          avgBaseIncome: 4200000,
          pensionRate: 0.72,
          totalContribution: 145152000,
          transitionRate: 0.98,
          redistributionRate: 0.89,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
        );

        // Assert
        final expectedHealthInsurance = (2200000 * 0.0699).round();
        expect(result.healthInsurance, equals(expectedHealthInsurance));
      });

      test('장기요양보험료는 건강보험료의 12.95%', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 1900000,
          annualPension: 24700000,
          totalPension: 494000000,
          retirementAge: 67,
          lifeExpectancy: 87,
          serviceYears: 28,
          avgBaseIncome: 3800000,
          pensionRate: 0.66,
          totalContribution: 114912000,
          transitionRate: 0.98,
          redistributionRate: 0.91,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
        );

        // Assert
        final expectedLongTermCare = (result.healthInsurance * 0.1295).round();
        expect(result.longTermCareInsurance, equals(expectedLongTermCare));
      });

      test('세후 월 연금 계산', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 2000000,
          annualPension: 26000000,
          totalPension: 520000000,
          retirementAge: 65,
          lifeExpectancy: 85,
          serviceYears: 30,
          avgBaseIncome: 4000000,
          pensionRate: 0.68,
          totalContribution: 129600000,
          transitionRate: 0.98,
          redistributionRate: 0.90,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
        );

        // Assert
        final totalDeductions = result.incomeTax +
            result.localTax +
            result.healthInsurance +
            result.longTermCareInsurance;

        expect(
          result.monthlyPensionAfterTax,
          equals(2000000 - totalDeductions),
        );
      });

      test('연간 세후 연금 계산', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 2400000,
          annualPension: 31200000,
          totalPension: 468000000,
          retirementAge: 70,
          lifeExpectancy: 85,
          serviceYears: 33,
          avgBaseIncome: 4400000,
          pensionRate: 0.74,
          totalContribution: 156816000,
          transitionRate: 0.98,
          redistributionRate: 0.88,
        );

        // Act
        final result = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
        );

        // Assert
        expect(
          result.annualPensionAfterTax,
          equals(result.monthlyPensionAfterTax * 13),
        );
      });

      test('나이에 따른 세금 차이 비교', () {
        // Arrange
        final pensionEstimate = PensionEstimate(
          monthlyPension: 2000000,
          annualPension: 26000000,
          totalPension: 520000000,
          retirementAge: 65,
          lifeExpectancy: 85,
          serviceYears: 30,
          avgBaseIncome: 4000000,
          pensionRate: 0.68,
          totalContribution: 129600000,
          transitionRate: 0.98,
          redistributionRate: 0.90,
        );

        // Act
        final result65 = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
          age: 65,
        );

        final result75 = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
          age: 75,
        );

        final result85 = service.calculateAfterTaxPension(
          pensionEstimate: pensionEstimate,
          age: 85,
        );

        // Assert
        // 나이가 많을수록 공제액이 커서 세금이 적음
        expect(result75.incomeTax, lessThan(result65.incomeTax));
        expect(result85.incomeTax, lessThan(result75.incomeTax));

        // 세후 실수령액은 나이가 많을수록 많음
        expect(
          result75.monthlyPensionAfterTax,
          greaterThan(result65.monthlyPensionAfterTax),
        );
        expect(
          result85.monthlyPensionAfterTax,
          greaterThan(result75.monthlyPensionAfterTax),
        );
      });
    });
  });
}
