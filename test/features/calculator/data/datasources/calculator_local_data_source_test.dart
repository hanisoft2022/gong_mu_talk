import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/data/datasources/calculator_local_data_source.dart';
import 'package:gong_mu_talk/features/calculator/data/models/salary_input_dto.dart';

void main() {
  late SalaryCalculatorLocalDataSource dataSource;

  setUp(() {
    dataSource = SalaryCalculatorLocalDataSource();
  });

  group('SalaryCalculatorLocalDataSource - 기본 계산', () {
    test('기본 월급만 있는 경우', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.monthlyTotal, 3000000);
      expect(result.allowancesTotal, 0);
      expect(result.dailyRate, closeTo(142857, 1)); // 3000000 / 21
      expect(result.yearlyTotal, 3000000 * 12);
    });

    test('수당이 포함된 경우', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {
          'mealAllowance': 130000,
          'transportationAllowance': 200000,
        },
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.allowancesTotal, 330000); // 13만 + 20만
      expect(result.monthlyTotal, 3330000); // 300만 + 33만
    });

    test('연간 보너스가 포함된 경우', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 5000000,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.yearlyTotal, 3000000 * 12 + 5000000); // 월급*12 + 보너스
    });
  });

  group('SalaryCalculatorLocalDataSource - 공제 계산', () {
    test('소득세와 지방소득세가 계산됨', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.incomeTax, greaterThan(0));
      expect(result.localIncomeTax, result.incomeTax * 0.1);
    });

    test('4대 보험료가 계산됨', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.pensionContribution, 270000); // 300만 * 9%
      expect(result.healthInsurance, greaterThan(0));
      expect(result.longTermCare, greaterThan(0));
      expect(result.longTermCare, result.healthInsurance * 0.1295);
    });

    test('총 공제액이 올바르게 계산됨', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 4000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      final expectedDeductions = result.incomeTax +
          result.localIncomeTax +
          result.pensionContribution +
          result.healthInsurance +
          result.longTermCare;

      expect(result.totalDeductions, closeTo(expectedDeductions, 0.01));
    });

    test('실수령액이 올바르게 계산됨', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 5000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      final expectedNetPay = result.monthlyTotal - result.totalDeductions;
      expect(result.netPay, closeTo(expectedNetPay, 0.01));
      
      // 실수령액이 총급여보다 작아야 함
      expect(result.netPay, lessThan(result.monthlyTotal));
    });
  });

  group('SalaryCalculatorLocalDataSource - 최저임금 비교', () {
    test('최저임금 대비 계산', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      // 2025년 최저임금: 시간당 10,030원
      // 최저일급: 10,030 * 8 = 80,240원
      expect(result.minimumDailyWage, 80240);
      
      // 일급이 최저일급보다 높아야 함
      expect(result.dailyRate, greaterThan(result.minimumDailyWage));
      expect(result.minimumWageGap, greaterThan(0));
    });

    test('최저일급 이하인 경우 음수 gap', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 1000000, // 매우 낮은 급여
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      // 일급: 1000000 / 21 = 약 47,619원
      // 최저일급: 80,240원
      // gap: 47,619 - 80,240 = -32,621원
      expect(result.minimumWageGap, lessThan(0));
    });
  });

  group('SalaryCalculatorLocalDataSource - notes 생성', () {
    test('상세 내역이 notes에 포함됨', () async {
      const dto = SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {
          'mealAllowance': 130000,
        },
        annualBonus: 1000000,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.notes, isNotEmpty);
      expect(result.notes.any((note) => note.contains('월급 상세')), isTrue);
      expect(result.notes.any((note) => note.contains('공제 상세')), isTrue);
      expect(result.notes.any((note) => note.contains('실수령액')), isTrue);
    });
  });

  group('SalaryCalculatorLocalDataSource - 실전 시나리오', () {
    test('공무원 9급 초봉 시뮬레이션', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 2300000,
        workingDaysPerMonth: 21,
        allowances: {
          'mealAllowance': 130000,
          'transportationAllowance': 200000,
        },
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.monthlyTotal, 2630000); // 230만 + 13만 + 20만
      expect(result.allowancesTotal, 330000);
      
      // 저소득이므로 공제율이 낮아야 함
      final deductionRate = result.totalDeductions / result.monthlyTotal;
      expect(deductionRate, lessThan(0.20)); // 20% 이하
      
      expect(result.netPay, greaterThan(2100000));
    });

    test('공무원 7급 중간 경력 시뮬레이션', () async {
      const dto = SalaryInputDto(
        baseMonthlySalary: 4000000,
        workingDaysPerMonth: 21,
        allowances: {
          'mealAllowance': 130000,
          'transportationAllowance': 200000,
          'positionAllowance': 100000,
        },
        annualBonus: 5000000,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '7',
        step: 15,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.monthlyTotal, 4430000); // 400만 + 수당 43만
      expect(result.yearlyTotal, 4430000 * 12 + 5000000);
      
      // 중간 소득 공제율 (약 15-20%)
      final deductionRate = result.totalDeductions / result.monthlyTotal;
      expect(deductionRate, greaterThan(0.10));
      expect(deductionRate, lessThan(0.25));
      
      expect(result.netPay, greaterThan(3500000));
      expect(result.netPay, lessThan(4000000));
    });

    test('고위 공무원 시뮬레이션', () async {
      const dto = SalaryInputDto(
        baseMonthlySalary: 8000000,
        workingDaysPerMonth: 21,
        allowances: {
          'mealAllowance': 130000,
          'transportationAllowance': 200000,
          'positionAllowance': 300000,
        },
        annualBonus: 15000000,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '5',
        step: 30,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.monthlyTotal, 8630000);
      
      // 고소득이므로 공제율이 높아야 함
      final deductionRate = result.totalDeductions / result.monthlyTotal;
      expect(deductionRate, greaterThan(0.15));
      
      // 연금은 상한 적용되어야 함
      expect(result.pensionContribution, lessThanOrEqualTo(815940));
      
      expect(result.netPay, lessThan(result.monthlyTotal));
    });

    test('근무일수가 다른 경우', () async {
      final dto20Days = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 20,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final dto22Days = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 22,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result20 = await dataSource.calculate(dto20Days);
      final result22 = await dataSource.calculate(dto22Days);

      // 근무일수가 적을수록 일급이 높아야 함
      expect(result20.dailyRate, greaterThan(result22.dailyRate));
      
      // 월 총급여는 동일
      expect(result20.monthlyTotal, result22.monthlyTotal);
    });
  });

  group('SalaryCalculatorLocalDataSource - 엣지 케이스', () {
    test('급여가 0인 경우', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 0,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.monthlyTotal, 0);
      expect(result.netPay, 0);
      expect(result.totalDeductions, 0);
    });

    test('근무일수가 0인 경우', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 0,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      expect(result.dailyRate, 0); // 0으로 나누기 방지
    });

    test('매우 큰 급여', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 50000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 100000000,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '1',
        step: 33,
        isAutoCalculated: false,
      );

      final result = await dataSource.calculate(dto);

      // 계산이 오버플로우 없이 완료되어야 함
      expect(result.monthlyTotal, 50000000);
      expect(result.yearlyTotal, greaterThan(500000000));
      
      // 상한 적용 확인
      expect(result.pensionContribution, lessThanOrEqualTo(815940));
    });
  });

  group('SalaryCalculatorLocalDataSource - 비동기 동작', () {
    test('계산에 시간이 소요됨 (딜레이 시뮬레이션)', () async {
      final dto = const SalaryInputDto(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: 'general',
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

      final stopwatch = Stopwatch()..start();
      await dataSource.calculate(dto);
      stopwatch.stop();

      // 180ms 딜레이가 있어야 함
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(170));
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });
  });
}
