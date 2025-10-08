import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';

void main() {
  group('TaxCalculationService', () {
    late TaxCalculationService service;

    setUp(() {
      service = TaxCalculationService();
    });

    group('calculateIncomeTax', () {
      test('김장한 교사 사례: 321만원, 부양가족 1명 → 약 86,330원', () {
        // Given: 김장한 교사 월급여 (총급여액)
        const monthlyGrossPay = 3210000;
        const dependents = 1;

        // When
        final incomeTax = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: dependents,
        );

        // Then: 목표 86,330원 ±10,000원 내외
        expect(incomeTax, greaterThanOrEqualTo(76330));
        expect(incomeTax, lessThanOrEqualTo(96330));
      });

      test('부양가족 0명일 때 세액이 더 높음', () {
        // Given
        const monthlyGrossPay = 3210000;

        // When
        final incomeTaxWith0Dependents = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: 0,
        );
        final incomeTaxWith1Dependent = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: 1,
        );

        // Then: 부양가족 0명일 때 세액이 더 높아야 함
        expect(incomeTaxWith0Dependents, greaterThan(incomeTaxWith1Dependent));
      });

      test('부양가족 수가 증가하면 세액이 감소', () {
        // Given
        const monthlyGrossPay = 3210000;

        // When
        final incomeTaxWith1Dependent = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: 1,
        );
        final incomeTaxWith2Dependents = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: 2,
        );
        final incomeTaxWith3Dependents = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: 3,
        );

        // Then
        expect(incomeTaxWith2Dependents, lessThan(incomeTaxWith1Dependent));
        expect(incomeTaxWith3Dependents, lessThan(incomeTaxWith2Dependents));
      });

      test('저소득자 (210만원)는 소득세가 낮음', () {
        // Given
        const monthlyGrossPay = 2100000;
        const dependents = 1;

        // When
        final incomeTax = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: dependents,
        );

        // Then: 저소득이므로 세액이 낮아야 함
        expect(incomeTax, lessThan(50000));
      });

      test('고소득자 (500만원)는 소득세가 높음', () {
        // Given
        const monthlyGrossPay = 5000000;
        const dependents = 1;

        // When
        final incomeTax = service.calculateIncomeTax(
          monthlyGrossPay,
          dependents: dependents,
        );

        // Then: 고소득이므로 세액이 높아야 함
        expect(incomeTax, greaterThan(200000));
      });
    });

    group('calculateLocalIncomeTax', () {
      test('지방소득세는 소득세의 10%', () {
        // Given
        const incomeTax = 86330;

        // When
        final localTax = service.calculateLocalIncomeTax(incomeTax);

        // Then
        expect(localTax, equals(8633));
      });
    });
  });
}
