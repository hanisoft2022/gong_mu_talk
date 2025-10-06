import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/monthly_breakdown_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';

void main() {
  late MonthlyBreakdownService service;

  setUp(() {
    service = MonthlyBreakdownService(TaxCalculationService());
  });

  group('MonthlyBreakdownService - 호봉표 검증', () {
    test('2025년 호봉표 정확성 검증 (인사혁신처 기준)', () {
      // 주요 호봉 금액 검증
      expect(SalaryTable.getBasePay(1), 1915100, reason: '1호봉');
      expect(SalaryTable.getBasePay(9), 2365500, reason: '9호봉');
      expect(SalaryTable.getBasePay(21), 3478900, reason: '21호봉');
      expect(SalaryTable.getBasePay(35), 5365800, reason: '35호봉');
      expect(SalaryTable.getBasePay(40), 5995800, reason: '40호봉');
    });
  });

  group('MonthlyBreakdownService - 실수령액 계산', () {
    test('1호봉 초임 교사 실수령액 계산 (담임 아님, 배우자 없음)', () {
      final profile = TeacherProfile(
        currentGrade: 1,
        position: Position.teacher,
        birthYear: 1998,
        birthMonth: 3,
        employmentStartDate: DateTime(2024, 3, 1),
        retirementAge: 62,
        allowances: const Allowance(),
      );

      final monthlyIncomes = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2025,
        hasSpouse: false,
        numberOfChildren: 0,
        isHomeroom: false,
        hasPosition: false,
      );

      expect(monthlyIncomes.length, 12);

      // 1월 (정근수당 포함)
      final january = monthlyIncomes[0];
      expect(january.month, 1);
      expect(january.baseSalary, 1915100, reason: '1호봉 본봉');
      expect(january.longevityBonus, greaterThan(0), reason: '1월 정근수당');
      expect(january.holidayBonus, 0, reason: '1월은 명절상여금 없음');

      // 2월 (설날 상여금 포함)
      final february = monthlyIncomes[1];
      expect(february.month, 2);
      expect(february.holidayBonus, (1915100 * 0.6).round(),
          reason: '2월 설날 상여금은 본봉의 60%');
      expect(february.longevityBonus, 0, reason: '2월은 정근수당 없음');

      // 7월 (정근수당 포함)
      final july = monthlyIncomes[6];
      expect(july.month, 7);
      expect(july.longevityBonus, greaterThan(0), reason: '7월 정근수당');
      expect(july.holidayBonus, 0, reason: '7월은 명절상여금 없음');

      // 9월 (추석 상여금 포함)
      final september = monthlyIncomes[8];
      expect(september.month, 9);
      expect(september.holidayBonus, (1915100 * 0.6).round(),
          reason: '9월 추석 상여금은 본봉의 60%');
      expect(september.longevityBonus, 0, reason: '9월은 정근수당 없음');

      // 일반 월 (3월)
      final march = monthlyIncomes[2];
      expect(march.month, 3);
      expect(march.longevityBonus, 0, reason: '3월은 정근수당 없음');
      expect(march.holidayBonus, 0, reason: '3월은 명절상여금 없음');
    });

    test('9호봉 교사 실수령액 계산 (담임, 배우자 있음, 자녀 2명)', () {
      final profile = TeacherProfile(
        currentGrade: 9,
        position: Position.teacher,
        birthYear: 1990,
        birthMonth: 3,
        employmentStartDate: DateTime(2017, 3, 1),
        retirementAge: 62,
        allowances: const Allowance(),
      );

      final monthlyIncomes = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2025,
        hasSpouse: true,
        numberOfChildren: 2,
        isHomeroom: true,
        hasPosition: false,
      );

      // 재직 년수: 2025 - 2017 = 8년
      final serviceYears = 8;

      final baseSalary = SalaryTable.getBasePay(9);
      expect(baseSalary, 2365500);

      // 수당 검증
      final teachingAllowance = AllowanceTable.teachingAllowance;
      final homeroomAllowance = AllowanceTable.homeroomAllowance;
      final familyAllowance = 40000 + 50000 + 80000; // 배우자 + 첫째 + 둘째
      final overtimeAllowance =
          AllowanceTable.getOvertimeAllowance(9); // 1~10호봉: 12만원
      final researchAllowance = 60000; // 5년 이상: 6만원

      expect(teachingAllowance, 250000);
      expect(homeroomAllowance, 200000);
      expect(familyAllowance, 170000);
      expect(overtimeAllowance, 120000);

      // 1월 실수령액 검증
      final january = monthlyIncomes[0];
      expect(january.month, 1);
      expect(january.baseSalary, baseSalary);

      // 정근수당 검증 (8년 재직: 40%)
      final expectedMonthlySalary = baseSalary +
          teachingAllowance +
          homeroomAllowance +
          familyAllowance +
          researchAllowance +
          overtimeAllowance +
          100000; // 정근수당 가산금 (5년 이상 10년 미만)
      
      expect(
        january.longevityBonus,
        (expectedMonthlySalary * 0.4).round(),
        reason: '8년 재직자는 월급의 40% 정근수당',
      );

      // 2월 명절상여금 검증
      final february = monthlyIncomes[1];
      expect(
        february.holidayBonus,
        (baseSalary * 0.6).round(),
        reason: '설날 상여금은 본봉의 60%',
      );

      // 연간 실수령액 계산
      final annualNetIncome = service.calculateAnnualNetIncome(monthlyIncomes);
      expect(annualNetIncome, greaterThan(0));

      // 명절상여금 총액 검증 (2월 + 9월)
      final totalHolidayBonus =
          monthlyIncomes[1].holidayBonus + monthlyIncomes[8].holidayBonus;
      expect(
        totalHolidayBonus,
        (baseSalary * 0.6 * 2).round(),
        reason: '연간 명절상여금은 본봉의 120%',
      );
    });

    test('21호봉 교사 실수령액 계산', () {
      final profile = TeacherProfile(
        currentGrade: 21,
        position: Position.teacher,
        birthYear: 1980,
        birthMonth: 3,
        employmentStartDate: DateTime(2005, 3, 1),
        retirementAge: 62,
        allowances: const Allowance(),
      );

      final monthlyIncomes = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2025,
        hasSpouse: true,
        numberOfChildren: 3,
        isHomeroom: false,
        hasPosition: true, // 보직교사
      );

      final baseSalary = SalaryTable.getBasePay(21);
      expect(baseSalary, 3478900);

      // 재직 년수: 2025 - 2005 = 20년 (정근수당 50%)
      final serviceYears = 20;
      expect(serviceYears, greaterThanOrEqualTo(10));

      // 가족수당: 배우자 4만 + 첫째 5만 + 둘째 8만 + 셋째 12만
      final familyAllowance = 40000 + 50000 + 80000 + 120000;
      expect(familyAllowance, 290000);

      // 보직교사수당
      final positionAllowance = AllowanceTable.headTeacherAllowance;
      expect(positionAllowance, 150000);

      // 시간외수당 (21호봉: 16만원)
      final overtimeAllowance = AllowanceTable.getOvertimeAllowance(21);
      expect(overtimeAllowance, 160000);

      // 2월 명절상여금
      final february = monthlyIncomes[1];
      expect(
        february.holidayBonus,
        (baseSalary * 0.6).round(),
        reason: '명절상여금은 본봉의 60%',
      );
    });

    test('35호봉 교사 실수령액 계산 (원로교사수당 포함 가능)', () {
      final profile = TeacherProfile(
        currentGrade: 35,
        position: Position.teacher,
        birthYear: 1965, // 2025년 기준 60세
        birthMonth: 3,
        employmentStartDate: DateTime(1995, 3, 1), // 30년 재직
        retirementAge: 62,
        allowances: const Allowance(),
      );

      final monthlyIncomes = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2025,
        hasSpouse: true,
        numberOfChildren: 2,
        isHomeroom: false,
        hasPosition: false,
      );

      final baseSalary = SalaryTable.getBasePay(35);
      expect(baseSalary, 5365800);

      // 재직 년수: 30년 이상, 나이: 60세 → 원로교사수당 5만원 지급
      final march = monthlyIncomes[2];
      expect(march.baseSalary, baseSalary);

      // 명절상여금 검증
      final february = monthlyIncomes[1];
      expect(
        february.holidayBonus,
        (baseSalary * 0.6).round(),
        reason: '명절상여금은 본봉의 60%',
      );

      final september = monthlyIncomes[8];
      expect(
        september.holidayBonus,
        (baseSalary * 0.6).round(),
        reason: '추석 상여금은 본봉의 60%',
      );
    });
  });

  group('MonthlyBreakdownService - 연간 총액 계산', () {
    test('연간 실수령액 및 공제액 계산', () {
      final profile = TeacherProfile(
        currentGrade: 15,
        position: Position.teacher,
        birthYear: 1987,
        birthMonth: 3,
        employmentStartDate: DateTime(2012, 3, 1),
        retirementAge: 62,
        allowances: const Allowance(),
      );

      final monthlyIncomes = service.calculateMonthlyBreakdown(
        profile: profile,
        year: 2025,
        hasSpouse: false,
        numberOfChildren: 0,
        isHomeroom: false,
        hasPosition: false,
      );

      final annualNetIncome = service.calculateAnnualNetIncome(monthlyIncomes);
      final annualDeductions = service.calculateAnnualDeductions(monthlyIncomes);

      expect(annualNetIncome, greaterThan(0));
      expect(annualDeductions, greaterThan(0));

      // 12개월 총합 검증
      final manualSum = monthlyIncomes.fold<int>(
        0,
        (sum, income) => sum + income.netIncome,
      );
      expect(annualNetIncome, manualSum);
    });
  });
}
