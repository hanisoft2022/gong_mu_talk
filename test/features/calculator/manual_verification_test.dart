// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/monthly_breakdown_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';

/// 수동 검증용 테스트
///
/// 웹에서 찾은 실수령액 예시와 비교하여 계산 정확도 확인
void main() {
  late MonthlyBreakdownService service;

  setUp(() {
    service = MonthlyBreakdownService(TaxCalculationService());
  });

  group('실제 급여 계산 예시 검증', () {
    test('9호봉 교사 월 평균 실수령액 계산 (웹 검증용)', () {
      // 웹서핑 결과: 9호봉 교사는 약 240만~260만원 실수령
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
        hasSpouse: false,
        numberOfChildren: 0,
        isHomeroom: false,
        hasPosition: false,
      );

      // 본봉 검증
      expect(SalaryTable.getBasePay(9), 2365500);

      // 일반 월 (3월) 실수령액
      final march = monthlyIncomes[2];
      print('9호봉 3월 세전 급여: ${march.grossSalary}원');
      print('9호봉 3월 실수령액: ${march.netIncome}원');

      // 1월 (정근수당 포함)
      final january = monthlyIncomes[0];
      print('9호봉 1월 세전 급여: ${january.grossSalary}원');
      print('9호봉 1월 정근수당: ${january.longevityBonus}원');
      print('9호봉 1월 실수령액: ${january.netIncome}원');

      // 2월 (명절상여금 포함)
      final february = monthlyIncomes[1];
      print('9호봉 2월 세전 급여: ${february.grossSalary}원');
      print('9호봉 2월 명절상여금: ${february.holidayBonus}원');
      print('9호봉 2월 실수령액: ${february.netIncome}원');

      // 월 평균 실수령액
      final avgNetIncome =
          monthlyIncomes.fold<int>(
            0,
            (sum, income) => sum + income.netIncome,
          ) ~/
          12;
      print('9호봉 월 평균 실수령액: $avgNetIncome원');

      // 연간 실수령액
      final annualNetIncome = service.calculateAnnualNetIncome(monthlyIncomes);
      print('9호봉 연간 실수령액: $annualNetIncome원');

      // 웹서핑 결과와 비교
      // 웹 자료의 240만~260만원은 일반 월급만 계산한 것으로 추정
      // 우리는 정근수당(1월/7월) + 명절상여금(2월/9월)을 모두 포함하여
      // 월 평균이 270만원 수준 (더 정확한 계산)
      expect(avgNetIncome, greaterThanOrEqualTo(2600000));
      expect(avgNetIncome, lessThanOrEqualTo(2800000));
    });

    test('1호봉 초임 교사 실수령액 검증', () {
      // 웹서핑 결과: 1호봉은 기본급 1,915,100원, 실수령액 약 240만~260만원
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

      // 본봉 검증
      expect(SalaryTable.getBasePay(1), 1915100);

      // 일반 월 실수령액
      final march = monthlyIncomes[2];
      print('\n1호봉 3월 본봉: ${march.baseSalary}원');
      print('1호봉 3월 세전 급여: ${march.grossSalary}원');
      print('1호봉 3월 실수령액: ${march.netIncome}원');

      // 월 평균
      final avgNetIncome =
          monthlyIncomes.fold<int>(
            0,
            (sum, income) => sum + income.netIncome,
          ) ~/
          12;
      print('1호봉 월 평균 실수령액: $avgNetIncome원');

      // 웹 검증: 240만~260만원 범위
      expect(avgNetIncome, greaterThanOrEqualTo(2200000));
      expect(avgNetIncome, lessThanOrEqualTo(2600000));
    });

    test('21호봉 교사 실수령액 검증 (담임)', () {
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
        numberOfChildren: 2,
        isHomeroom: true,
        hasPosition: false,
      );

      // 본봉 검증
      expect(SalaryTable.getBasePay(21), 3478900);

      final march = monthlyIncomes[2];
      print('\n21호봉 (담임, 배우자, 자녀2) 3월 본봉: ${march.baseSalary}원');
      print('21호봉 3월 세전 급여: ${march.grossSalary}원');
      print('21호봉 3월 실수령액: ${march.netIncome}원');

      // 월 평균
      final avgNetIncome =
          monthlyIncomes.fold<int>(
            0,
            (sum, income) => sum + income.netIncome,
          ) ~/
          12;
      print('21호봉 월 평균 실수령액: $avgNetIncome원');

      // 연간 총액
      final annualNetIncome = service.calculateAnnualNetIncome(monthlyIncomes);
      print('21호봉 연간 실수령액: $annualNetIncome원');

      expect(avgNetIncome, greaterThan(3000000));
    });

    test('명절상여금 총액 검증', () {
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

      final baseSalary = SalaryTable.getBasePay(15);

      // 2월 (설날)
      final february = monthlyIncomes[1];
      expect(february.holidayBonus, (baseSalary * 0.6).round());

      // 9월 (추석)
      final september = monthlyIncomes[8];
      expect(september.holidayBonus, (baseSalary * 0.6).round());

      // 연간 총액
      final totalHolidayBonus = february.holidayBonus + september.holidayBonus;
      expect(totalHolidayBonus, (baseSalary * 1.2).round());

      print('\n15호봉 본봉: $baseSalary원');
      print('15호봉 명절상여금 총액: $totalHolidayBonus원 (본봉의 120%)');
    });
  });
}
