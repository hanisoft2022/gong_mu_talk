import 'package:injectable/injectable.dart';

import '../entities/career_event.dart';
import '../entities/career_simulation_result.dart';
import '../entities/salary_allowance_type.dart';
import '../entities/salary_input.dart';

import '../repositories/salary_table_repository.dart';
import 'insurance_calculator.dart';
import 'tax_calculator.dart';

/// 경력 시뮬레이션 엔진
/// 
/// 경력 시나리오를 기반으로 생애 소득을 시뮬레이션
@lazySingleton
class CareerSimulationEngine {
  CareerSimulationEngine({
    required SalaryTableRepository salaryTableRepository,
    TaxCalculator? taxCalculator,
    InsuranceCalculator? insuranceCalculator,
  })  : _salaryTableRepository = salaryTableRepository,
        _taxCalculator = taxCalculator ?? TaxCalculator(),
        _insuranceCalculator = insuranceCalculator ?? InsuranceCalculator();

  final SalaryTableRepository _salaryTableRepository;
  final TaxCalculator _taxCalculator;
  final InsuranceCalculator _insuranceCalculator;

  /// 시뮬레이션 실행
  /// 
  /// [initialInput]: 초기 급여 정보
  /// [scenario]: 경력 시나리오
  /// [birthYear]: 출생연도
  /// [retirementYear]: 퇴직연도
  Future<CareerSimulationResult> simulate({
    required SalaryInput initialInput,
    required CareerScenario scenario,
    required int birthYear,
    required int retirementYear,
  }) async {
    final projections = <YearlyCareerProjection>[];
    
    // 현재 상태
    var currentGrade = initialInput.gradeId;
    var currentStep = initialInput.step;
    var currentYear = initialInput.appointmentYear;
    var currentBaseSalary = initialInput.baseMonthlySalary;
    var currentAllowances = Map<SalaryAllowanceType, double>.from(
      initialInput.allowances,
    );

    // 누적 값
    double cumulativeGross = 0;
    double cumulativeNet = 0;
    double cumulativePension = 0;

    // 연도별 시뮬레이션
    while (currentYear <= retirementYear) {
      final age = currentYear - birthYear;
      final yearEvents = scenario.getEventsForYear(currentYear);

      // 1. 이벤트 적용 전 기본 계산
      // 봉급표에서 현재 계급/호봉의 기본급 조회
      final salaryTable = await _salaryTableRepository.getSalaryTable(
        year: currentYear,
        track: initialInput.track.name,
      );

      if (salaryTable != null) {
        final tableBaseSalary = salaryTable.getSalary(currentGrade, currentStep);
        if (tableBaseSalary != null) {
          currentBaseSalary = tableBaseSalary;
        }
      }

      // 2. 이벤트 적용
      for (final event in yearEvents) {
        if (event is PromotionEvent) {
          // 승진
          currentGrade = event.newGrade;
          currentStep = event.newStep;
          
          // 새 계급의 기본급 조회
          if (salaryTable != null) {
            final newBaseSalary = salaryTable.getSalary(
              currentGrade,
              currentStep,
            );
            if (newBaseSalary != null) {
              currentBaseSalary = newBaseSalary;
            }
          }
        } else if (event is StepIncrementEvent) {
          // 정기승급
          currentStep += event.increment;
          
          // 승급 후 기본급 조회
          if (salaryTable != null) {
            final newBaseSalary = salaryTable.getSalary(
              currentGrade,
              currentStep,
            );
            if (newBaseSalary != null) {
              currentBaseSalary = newBaseSalary;
            }
          }
        } else if (event is LeaveEvent) {
          // 휴직
          // 무급휴직이면 급여 없음
          if (!event.isPaid) {
            currentBaseSalary = 0;
            currentAllowances = {};
          }
        } else if (event is TransferEvent) {
          // 전보
          if (event.baseSalaryChange != null) {
            currentBaseSalary = event.baseSalaryChange!;
          }
          
          // 수당 변경
          for (final entry in event.allowanceChanges.entries) {
            currentAllowances[entry.key] = entry.value;
          }
        } else if (event is SalaryAdjustmentEvent) {
          // 급여 조정
          currentBaseSalary *= (1 + event.adjustmentRate);
        }
      }

      // 3. 급여 계산
      final allowancesTotal = currentAllowances.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      final monthlyGross = currentBaseSalary + allowancesTotal;

      // 4. 세금 및 공제 계산
      final taxBreakdown = _taxCalculator.calculateTotalTax(
        monthlyGross: monthlyGross,
        dependents: 1,
      );

      final pensionBase = _insuranceCalculator.applyPensionBaseLimit(
        monthlyGross,
      );
      final insuranceBreakdown = _insuranceCalculator.calculateTotalInsurance(
        monthlyGross: monthlyGross,
        pensionBase: pensionBase,
      );

      final totalDeductions = taxBreakdown.totalTax +
          insuranceBreakdown.totalInsurance;
      final monthlyNet = monthlyGross - totalDeductions;

      // 5. 연간 금액 계산
      final yearlyGross = monthlyGross * 12;
      final yearlyNet = monthlyNet * 12;
      final yearlyPension = insuranceBreakdown.pensionContribution * 12;

      // 6. 누적 계산
      cumulativeGross += yearlyGross;
      cumulativeNet += yearlyNet;
      cumulativePension += yearlyPension;

      // 7. 연도별 결과 저장
      projections.add(
        YearlyCareerProjection(
          year: currentYear,
          age: age,
          grade: currentGrade,
          step: currentStep,
          baseSalary: currentBaseSalary,
          monthlyGross: monthlyGross,
          monthlyNet: monthlyNet,
          yearlyGross: yearlyGross,
          yearlyNet: yearlyNet,
          pensionContribution: insuranceBreakdown.pensionContribution,
          cumulativeGross: cumulativeGross,
          cumulativeNet: cumulativeNet,
          cumulativePension: cumulativePension,
          events: yearEvents,
        ),
      );

      currentYear++;
    }

    // 8. 평균 기준소득월액 계산 (연금용)
    final totalMonths = projections.length * 12;
    final avgMonthlyIncome = totalMonths > 0
        ? cumulativeGross / totalMonths.toDouble()
        : 0.0;

    return CareerSimulationResult(
      yearlyProjections: projections,
      totalLifetimeGross: cumulativeGross,
      totalLifetimeNet: cumulativeNet,
      totalPensionContributions: cumulativePension,
      averageMonthlyIncome: avgMonthlyIncome,
      scenario: scenario,
    );
  }

  /// 여러 시나리오 비교
  Future<List<CareerSimulationResult>> compareScenarios({
    required SalaryInput initialInput,
    required List<CareerScenario> scenarios,
    required int birthYear,
    required int retirementYear,
  }) async {
    final results = <CareerSimulationResult>[];

    for (final scenario in scenarios) {
      final result = await simulate(
        initialInput: initialInput,
        scenario: scenario,
        birthYear: birthYear,
        retirementYear: retirementYear,
      );
      results.add(result);
    }

    return results;
  }
}
