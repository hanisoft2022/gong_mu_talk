import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/insurance_calculator.dart';

void main() {
  late InsuranceCalculator calculator;

  setUp(() {
    calculator = InsuranceCalculator();
  });

  group('InsuranceCalculator - 공무원연금', () {
    test('공무원연금 기여율 9%', () {
      expect(InsuranceCalculator.pensionRate, 0.09);
    });

    test('월 300만원의 공무원연금', () {
      final pension = calculator.calculatePensionContribution(3000000);
      expect(pension, 270000); // 300만원 * 9%
    });

    test('월 500만원의 공무원연금', () {
      final pension = calculator.calculatePensionContribution(5000000);
      expect(pension, 450000); // 500만원 * 9%
    });

    test('0원은 연금 0원', () {
      final pension = calculator.calculatePensionContribution(0);
      expect(pension, 0);
    });

    test('소수점 처리', () {
      final pension = calculator.calculatePensionContribution(3333333);
      expect(pension, closeTo(299999.97, 0.01));
    });
  });

  group('InsuranceCalculator - 건강보험', () {
    test('건강보험료율 3.545%', () {
      expect(InsuranceCalculator.healthInsuranceRate, 0.03545);
    });

    test('월 300만원의 건강보험료', () {
      final health = calculator.calculateHealthInsurance(3000000);
      expect(health, 106350); // 300만원 * 3.545%
    });

    test('월 500만원의 건강보험료', () {
      final health = calculator.calculateHealthInsurance(5000000);
      expect(health, 177250); // 500만원 * 3.545%
    });

    test('0원은 건강보험료 0원', () {
      final health = calculator.calculateHealthInsurance(0);
      expect(health, 0);
    });
  });

  group('InsuranceCalculator - 장기요양보험', () {
    test('장기요양보험료율 12.95% (건강보험료 기준)', () {
      expect(InsuranceCalculator.longTermCareRate, 0.1295);
    });

    test('건강보험료 10만원의 장기요양보험료', () {
      final care = calculator.calculateLongTermCare(100000);
      expect(care, 12950); // 10만원 * 12.95%
    });

    test('건강보험료 20만원의 장기요양보험료', () {
      final care = calculator.calculateLongTermCare(200000);
      expect(care, 25900); // 20만원 * 12.95%
    });

    test('건강보험료 0원이면 장기요양보험료도 0원', () {
      final care = calculator.calculateLongTermCare(0);
      expect(care, 0);
    });
  });

  group('InsuranceCalculator - 전체 보험료 계산', () {
    test('월 300만원 급여의 전체 보험료', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 3000000,
      );

      expect(breakdown.pensionContribution, 270000); // 9%
      expect(breakdown.healthInsurance, 106350); // 3.545%
      expect(breakdown.longTermCare, closeTo(13772.325, 0.01)); // 106350 * 12.95%
      
      final expectedTotal = breakdown.pensionContribution +
          breakdown.healthInsurance +
          breakdown.longTermCare;
      expect(breakdown.totalInsurance, closeTo(expectedTotal, 0.01));
    });

    test('월 500만원 급여의 전체 보험료', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 5000000,
      );

      expect(breakdown.pensionContribution, 450000);
      expect(breakdown.healthInsurance, 177250);
      expect(breakdown.longTermCare, closeTo(22953.875, 0.01));
      expect(breakdown.totalInsurance, greaterThan(650000));
    });

    test('별도의 연금 기준소득월액 지정', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 5000000,
        pensionBase: 4000000, // 연금은 400만원 기준
      );

      expect(breakdown.pensionContribution, 360000); // 400만원 * 9%
      expect(breakdown.healthInsurance, 177250); // 500만원 * 3.545%
      expect(breakdown.totalInsurance, greaterThan(550000));
    });
  });

  group('InsuranceCalculator - 공무원연금 기준소득월액 상하한', () {
    test('상한액 적용 - 906.6만원', () {
      final limited = calculator.applyPensionBaseLimit(10000000);
      expect(limited, 9066000);
    });

    test('하한액 적용 - 30.9만원', () {
      final limited = calculator.applyPensionBaseLimit(200000);
      expect(limited, 309000);
    });

    test('상하한 범위 내는 그대로 유지', () {
      final limited = calculator.applyPensionBaseLimit(5000000);
      expect(limited, 5000000);
    });

    test('상한 경계값', () {
      final atLimit = calculator.applyPensionBaseLimit(9066000);
      expect(atLimit, 9066000);

      final overLimit = calculator.applyPensionBaseLimit(9066001);
      expect(overLimit, 9066000);
    });

    test('하한 경계값', () {
      final atLimit = calculator.applyPensionBaseLimit(309000);
      expect(atLimit, 309000);

      final underLimit = calculator.applyPensionBaseLimit(308999);
      expect(underLimit, 309000);
    });
  });

  group('InsuranceCalculator - 건강보험 보수월액 상한', () {
    test('상한액 적용 - 871.5만원', () {
      final limited = calculator.applyHealthInsuranceLimit(10000000);
      expect(limited, 8715000);
    });

    test('상한 범위 내는 그대로 유지', () {
      final limited = calculator.applyHealthInsuranceLimit(5000000);
      expect(limited, 5000000);
    });

    test('상한 경계값', () {
      final atLimit = calculator.applyHealthInsuranceLimit(8715000);
      expect(atLimit, 8715000);

      final overLimit = calculator.applyHealthInsuranceLimit(8715001);
      expect(overLimit, 8715000);
    });

    test('건강보험은 하한이 없음', () {
      final limited = calculator.applyHealthInsuranceLimit(100000);
      expect(limited, 100000);
    });
  });

  group('InsuranceCalculator - 실전 시나리오', () {
    test('공무원 9급 초봉 (월 230만원)', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 2300000,
      );

      // 하한액 적용 확인
      expect(breakdown.pensionContribution, greaterThanOrEqualTo(27810)); // 309000 * 9%
      expect(breakdown.healthInsurance, closeTo(81535, 1)); // 2300000 * 3.545%
      expect(breakdown.totalInsurance, lessThan(130000));
    });

    test('공무원 7급 중간 경력 (월 400만원)', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 4000000,
      );

      expect(breakdown.pensionContribution, 360000); // 400만원 * 9%
      expect(breakdown.healthInsurance, 141800); // 400만원 * 3.545%
      expect(breakdown.longTermCare, closeTo(18363.1, 0.1));
      expect(breakdown.totalInsurance, closeTo(520163.1, 1));
    });

    test('고위 공무원 (월 1000만원) - 상한 적용', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 10000000,
      );

      // 연금은 상한 적용
      expect(breakdown.pensionContribution, 815940); // 9066000 * 9%
      
      // 건강보험도 상한 적용
      expect(breakdown.healthInsurance, 308946.75); // 8715000 * 3.545%
      
      // 장기요양은 건강보험료 기준
      expect(breakdown.longTermCare, closeTo(40009, 1));
      
      expect(breakdown.totalInsurance, greaterThan(1160000));
      expect(breakdown.totalInsurance, lessThan(1170000));
    });

    test('저소득 공무원 (월 150만원) - 하한 적용', () {
      // 실제로는 150만원 급여가 최저임금 이하이지만 테스트
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 1500000,
      );

      // 연금은 하한 적용
      expect(breakdown.pensionContribution, 27810); // 309000 * 9%
      
      // 건강보험은 실제 급여 기준
      expect(breakdown.healthInsurance, 53175); // 1500000 * 3.545%
      
      expect(breakdown.totalInsurance, lessThan(90000));
    });
  });

  group('InsuranceCalculator - 국민연금 계산기', () {
    test('국민연금 기여율 4.5%', () {
      expect(NationalPensionCalculator.pensionRate, 0.045);
    });

    test('월 300만원의 국민연금', () {
      final calculator = NationalPensionCalculator();
      final pension = calculator.calculatePensionContribution(3000000);
      expect(pension, 135000); // 300만원 * 4.5%
    });

    test('국민연금 상한 적용 (590만원)', () {
      final calculator = NationalPensionCalculator();
      final pension = calculator.calculatePensionContribution(10000000);
      expect(pension, 265500); // 5900000 * 4.5%
    });

    test('국민연금 하한 적용 (39만원)', () {
      final calculator = NationalPensionCalculator();
      final pension = calculator.calculatePensionContribution(200000);
      expect(pension, 17550); // 390000 * 4.5%
    });
  });

  group('InsuranceCalculator - 엣지 케이스', () {
    test('급여가 음수인 경우', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: -1000000,
      );
      
      // 음수 급여에 대한 처리 (실제로는 발생하지 않지만)
      // 현재 구현은 음수를 그대로 계산하므로 음수 결과
      expect(breakdown.pensionContribution, isNegative);
    });

    test('매우 큰 금액 (1억원)', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 100000000,
      );
      
      // 상한 적용 확인
      expect(breakdown.pensionContribution, 815940);
      expect(breakdown.healthInsurance, 308946.75);
      expect(breakdown.totalInsurance, lessThan(1200000));
    });

    test('소수점 금액', () {
      final breakdown = calculator.calculateTotalInsurance(
        monthlyGross: 3333333.33,
      );
      
      expect(breakdown.pensionContribution, closeTo(299999.9997, 0.01));
      expect(breakdown.healthInsurance, closeTo(118166.6647, 0.01));
      expect(breakdown.totalInsurance, greaterThan(410000));
    });
  });
}
