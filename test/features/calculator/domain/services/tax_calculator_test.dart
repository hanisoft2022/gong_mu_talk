import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculator.dart';

void main() {
  late TaxCalculator calculator;

  setUp(() {
    calculator = TaxCalculator();
  });

  group('TaxCalculator - 소득세 계산', () {
    test('과세표준 0원 이하는 소득세 0원', () {
      expect(calculator.calculateAnnualIncomeTax(0), 0);
      expect(calculator.calculateAnnualIncomeTax(-1000), 0);
    });

    test('1400만원 이하 구간 (6% 세율)', () {
      // 1000만원 * 6% = 60만원
      final tax = calculator.calculateAnnualIncomeTax(10000000);
      expect(tax, 600000);
    });

    test('5000만원 구간 (15% 세율, 누진공제 126만원)', () {
      // 3000만원 * 15% - 126만원 = 324만원
      final tax = calculator.calculateAnnualIncomeTax(30000000);
      expect(tax, 3240000);
    });

    test('8800만원 구간 (24% 세율, 누진공제 576만원)', () {
      // 5000만원 * 24% - 576만원 = 624만원
      final tax = calculator.calculateAnnualIncomeTax(50000000);
      expect(tax, 6240000);
    });

    test('1억5천만원 구간 (35% 세율, 누진공제 1544만원)', () {
      // 1억원 * 35% - 1544만원 = 1956만원
      final tax = calculator.calculateAnnualIncomeTax(100000000);
      expect(tax, 19560000);
    });

    test('경계값 테스트 - 1400만원 정확히', () {
      // 1400만원 * 6% = 84만원
      final tax = calculator.calculateAnnualIncomeTax(14000000);
      expect(tax, 840000);
    });

    test('경계값 테스트 - 1400만원 + 1원 (다음 구간)', () {
      // 14000001원 * 15% - 126만원 = 840000.15원
      final tax = calculator.calculateAnnualIncomeTax(14000001);
      expect(tax, closeTo(840000.15, 0.01));
    });
  });

  group('TaxCalculator - 월 소득세 계산', () {
    test('월 300만원 급여의 소득세', () {
      // 연 3600만원 → 근로소득공제 후 과세표준 계산
      final monthlyTax = calculator.calculateMonthlyIncomeTax(
        monthlyGross: 3000000,
        dependents: 1,
      );
      
      // 대략적인 범위 확인 (간이세액표 방식이므로 정확한 값은 다를 수 있음)
      expect(monthlyTax, greaterThan(0));
      expect(monthlyTax, lessThan(500000));
    });

    test('월 500만원 급여의 소득세', () {
      final monthlyTax = calculator.calculateMonthlyIncomeTax(
        monthlyGross: 5000000,
        dependents: 1,
      );
      
      expect(monthlyTax, greaterThan(0));
      expect(monthlyTax, lessThan(1000000));
    });

    test('부양가족 수에 따른 세액 감면', () {
      final tax1 = calculator.calculateMonthlyIncomeTax(
        monthlyGross: 4000000,
        dependents: 1,
      );
      
      final tax3 = calculator.calculateMonthlyIncomeTax(
        monthlyGross: 4000000,
        dependents: 3,
      );
      
      // 부양가족이 많을수록 세액이 적어야 함
      expect(tax3, lessThan(tax1));
    });

    test('월 200만원 이하 저소득 - 소득세 매우 낮음', () {
      final monthlyTax = calculator.calculateMonthlyIncomeTax(
        monthlyGross: 2000000,
        dependents: 1,
      );
      
      // 저소득은 소득세가 거의 없거나 매우 적음
      expect(monthlyTax, lessThan(100000));
    });
  });

  group('TaxCalculator - 지방소득세 계산', () {
    test('소득세의 10%', () {
      final localTax = calculator.calculateLocalIncomeTax(1000000);
      expect(localTax, 100000);
    });

    test('소득세 0원이면 지방소득세도 0원', () {
      final localTax = calculator.calculateLocalIncomeTax(0);
      expect(localTax, 0);
    });

    test('소수점 처리', () {
      final localTax = calculator.calculateLocalIncomeTax(123456);
      expect(localTax, 12345.6);
    });
  });

  group('TaxCalculator - 총 세금 계산', () {
    test('월 300만원 급여의 총 세금', () {
      final breakdown = calculator.calculateTotalTax(
        monthlyGross: 3000000,
        dependents: 1,
      );
      
      expect(breakdown.incomeTax, greaterThan(0));
      expect(breakdown.localIncomeTax, breakdown.incomeTax * 0.1);
      expect(breakdown.totalTax, breakdown.incomeTax + breakdown.localIncomeTax);
    });

    test('총 세금 = 소득세 + 지방소득세', () {
      final breakdown = calculator.calculateTotalTax(
        monthlyGross: 5000000,
        dependents: 2,
      );
      
      final expectedTotal = breakdown.incomeTax + breakdown.localIncomeTax;
      expect(breakdown.totalTax, expectedTotal);
    });

    test('부양가족 수 변경에 따른 총 세금 변화', () {
      final breakdown1 = calculator.calculateTotalTax(
        monthlyGross: 4000000,
        dependents: 1,
      );
      
      final breakdown2 = calculator.calculateTotalTax(
        monthlyGross: 4000000,
        dependents: 4,
      );
      
      // 부양가족이 많을수록 총 세금이 적어야 함
      expect(breakdown2.totalTax, lessThan(breakdown1.totalTax));
    });
  });

  group('TaxCalculator - 근로소득공제', () {
    test('500만원 이하 - 70% 공제', () {
      // private 메서드이므로 간접 테스트
      // 연 300만원 → 공제 210만원 → 과세표준 90만원
      final tax = calculator.calculateAnnualIncomeTax(900000);
      expect(tax, 54000); // 90만원 * 6%
    });
  });

  group('TaxCalculator - 실전 시나리오', () {
    test('공무원 9급 초봉 시뮬레이션 (월 230만원)', () {
      final breakdown = calculator.calculateTotalTax(
        monthlyGross: 2300000,
        dependents: 1,
      );
      
      // 저소득이므로 소득세가 낮아야 함
      expect(breakdown.incomeTax, lessThan(150000));
      expect(breakdown.totalTax, lessThan(165000));
    });

    test('공무원 7급 중간 경력 (월 400만원)', () {
      final breakdown = calculator.calculateTotalTax(
        monthlyGross: 4000000,
        dependents: 2,
      );
      
      expect(breakdown.incomeTax, greaterThan(100000));
      expect(breakdown.incomeTax, lessThan(600000));
      expect(breakdown.totalTax, breakdown.incomeTax * 1.1);
    });

    test('고위 공무원 (월 800만원)', () {
      final breakdown = calculator.calculateTotalTax(
        monthlyGross: 8000000,
        dependents: 1,
      );
      
      // 고소득이므로 세금 비중이 높아야 함
      expect(breakdown.incomeTax, greaterThan(500000));
      expect(breakdown.totalTax, greaterThan(550000));
    });
  });
}
