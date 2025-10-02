import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/career_event.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_allowance_type.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_input.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_table.dart' show SalaryTable, GradeSteps;
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_track.dart';
import 'package:gong_mu_talk/features/calculator/domain/repositories/salary_table_repository.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/career_simulation_engine.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/insurance_calculator.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculator.dart';
import 'package:mocktail/mocktail.dart';

class MockSalaryTableRepository extends Mock implements SalaryTableRepository {}

void main() {
  late CareerSimulationEngine engine;
  late MockSalaryTableRepository mockRepository;
  late TaxCalculator taxCalculator;
  late InsuranceCalculator insuranceCalculator;

  setUp(() {
    mockRepository = MockSalaryTableRepository();
    taxCalculator = TaxCalculator();
    insuranceCalculator = InsuranceCalculator();
    engine = CareerSimulationEngine(
      salaryTableRepository: mockRepository,
      taxCalculator: taxCalculator,
      insuranceCalculator: insuranceCalculator,
    );
  });

  group('CareerSimulationEngine - 기본 시뮬레이션', () {
    test('단일 연도 시뮬레이션 - 승급 없음', () async {
      // Given: 2025년 한 해만 시뮬레이션
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {SalaryAllowanceType.positionAllowance: 200000},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '평범한 경력',
        events: [],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 10,
            steps: {1: 3000000, 2: 3100000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then
      expect(result.yearlyProjections.length, 1);
      final projection = result.yearlyProjections.first;
      expect(projection.year, 2025);
      expect(projection.age, 35);
      expect(projection.grade, '7급');
      expect(projection.step, 1);
      expect(projection.baseSalary, 3000000);
      expect(projection.monthlyGross, 3200000); // 기본급 + 수당
      expect(projection.yearlyGross, 38400000); // 월 × 12
    });

    test('정기승급 이벤트 적용', () async {
      // Given: 2025년에 1호봉 승급
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '정기승급',
        events: [
          StepIncrementEvent(year: 2025, increment: 1),
        ],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000, 2: 3100000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then
      final projection = result.yearlyProjections.first;
      expect(projection.step, 2); // 1호봉 → 2호봉
      expect(projection.baseSalary, 3100000); // 승급 후 기본급
    });

    test('승진 이벤트 적용', () async {
      // Given: 2026년에 6급으로 승진
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 5,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '승진',
        events: [
          PromotionEvent(year: 2026, newGrade: '6급', newStep: 1),
        ],
      );

      final salaryTable2025 = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {5: 3500000},
          ),
        },
      );

      final salaryTable2026 = const SalaryTable(
        year: 2026,
        track: 'general',
        grades: {
          '6급': GradeSteps(
            gradeId: '6급',
            gradeName: '6급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3800000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable2025);

      when(
        () => mockRepository.getSalaryTable(
          year: 2026,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable2026);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2026,
      );

      // Then
      expect(result.yearlyProjections.length, 2);

      final projection2025 = result.yearlyProjections[0];
      expect(projection2025.grade, '7급');
      expect(projection2025.step, 5);
      expect(projection2025.baseSalary, 3500000);

      final projection2026 = result.yearlyProjections[1];
      expect(projection2026.grade, '6급'); // 승진
      expect(projection2026.step, 1); // 1호봉으로 재설정
      expect(projection2026.baseSalary, 3800000); // 6급 1호봉 기본급
    });
  });

  group('CareerSimulationEngine - 급여 조정 이벤트', () {
    test('급여 인상 이벤트 적용 (3% 인상)', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '급여 인상',
        events: [
          SalaryAdjustmentEvent(year: 2025, adjustmentRate: 0.03), // 3% 인상
        ],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then
      final projection = result.yearlyProjections.first;
      expect(projection.baseSalary, closeTo(3090000, 1)); // 3000000 × 1.03
    });

    test('전보 이벤트 - 수당 변경', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {SalaryAllowanceType.positionAllowance: 100000},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '전보',
        events: [
          TransferEvent(
            year: 2025,
            allowanceChanges: {
              SalaryAllowanceType.positionAllowance: 200000, // 직책수당 100000 → 200000
              SalaryAllowanceType.specialDutyAllowance: 150000, // 특수업무수당 신규 추가
            },
          ),
        ],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then
      final projection = result.yearlyProjections.first;
      expect(projection.baseSalary, 3000000);
      expect(projection.monthlyGross, 3350000); // 3000000 + 200000 + 150000
    });
  });

  group('CareerSimulationEngine - 휴직 이벤트', () {
    test('무급휴직 - 급여 0원', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '무급휴직',
        events: [
          LeaveEvent(
            year: 2025,
            durationMonths: 12,
            leaveType: LeaveType.other,
            isPaid: false,
          ),
        ],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then
      final projection = result.yearlyProjections.first;
      expect(projection.baseSalary, 0); // 무급휴직
      expect(projection.monthlyGross, 0);
      expect(projection.yearlyGross, 0);
      // Note: monthlyNet is negative due to minimum pension base limit (309,000 won)
      // Pension contribution = 309,000 * 9% = 27,810 won
      expect(projection.monthlyNet, closeTo(-27810, 1));
    });
  });

  group('CareerSimulationEngine - 누적 계산', () {
    test('생애 소득 누적 계산', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '2년 근무',
        events: [],
      );

      final salaryTable2025 = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
        },
      );

      final salaryTable2026 = const SalaryTable(
        year: 2026,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3100000},
          ), // 약간 인상
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable2025);

      when(
        () => mockRepository.getSalaryTable(
          year: 2026,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable2026);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2026,
      );

      // Then
      expect(result.yearlyProjections.length, 2);

      final projection2025 = result.yearlyProjections[0];
      final projection2026 = result.yearlyProjections[1];

      // 누적 총급여 검증
      expect(
        projection2025.cumulativeGross,
        projection2025.yearlyGross,
      );
      expect(
        projection2026.cumulativeGross,
        projection2025.yearlyGross + projection2026.yearlyGross,
      );

      // 최종 누적 값 검증
      expect(
        result.totalLifetimeGross,
        projection2026.cumulativeGross,
      );

      // 평균 기준소득월액 검증
      final totalMonths = 24; // 2년 = 24개월
      expect(
        result.averageMonthlyIncome,
        result.totalLifetimeGross / totalMonths,
      );
    });

    test('연금 기여금 누적 계산', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 5000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '5급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '1년 근무',
        events: [],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '5급': GradeSteps(
            gradeId: '5급',
            gradeName: '5급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 5000000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then
      final projection = result.yearlyProjections.first;

      // 연금 기여금 = 5000000 × 9% = 450000 (월)
      expect(projection.pensionContribution, 450000);

      // 연간 연금 기여금 = 450000 × 12 = 5400000
      expect(
        projection.cumulativePension,
        closeTo(5400000, 1),
      );

      expect(
        result.totalPensionContributions,
        projection.cumulativePension,
      );
    });
  });

  group('CareerSimulationEngine - 시나리오 비교', () {
    test('여러 시나리오 비교', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final conservativeScenario = const CareerScenario(
        name: '보수적 경력',
        events: [],
      );

      final aggressiveScenario = const CareerScenario(
        name: '공격적 경력',
        events: [
          PromotionEvent(year: 2026, newGrade: '6급', newStep: 1),
          PromotionEvent(year: 2028, newGrade: '5급', newStep: 1),
        ],
      );

      // Mock salary tables
      final salaryTable2025 = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
        },
      );

      final salaryTable2026 = const SalaryTable(
        year: 2026,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
          '6급': GradeSteps(
            gradeId: '6급',
            gradeName: '6급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3500000},
          ),
        },
      );

      final salaryTable2027 = const SalaryTable(
        year: 2027,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
          '6급': GradeSteps(
            gradeId: '6급',
            gradeName: '6급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3500000},
          ),
        },
      );

      final salaryTable2028 = const SalaryTable(
        year: 2028,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
          '6급': GradeSteps(
            gradeId: '6급',
            gradeName: '6급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3500000},
          ),
          '5급': GradeSteps(
            gradeId: '5급',
            gradeName: '5급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 4000000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: any(named: 'year'),
          track: any(named: 'track'),
        ),
      ).thenAnswer((invocation) async {
        final year = invocation.namedArguments[const Symbol('year')] as int;
        switch (year) {
          case 2025:
            return salaryTable2025;
          case 2026:
            return salaryTable2026;
          case 2027:
            return salaryTable2027;
          case 2028:
            return salaryTable2028;
          default:
            return salaryTable2025;
        }
      });

      // When
      final results = await engine.compareScenarios(
        initialInput: input,
        scenarios: [conservativeScenario, aggressiveScenario],
        birthYear: 1990,
        retirementYear: 2028,
      );

      // Then
      expect(results.length, 2);

      final conservativeResult = results[0];
      final aggressiveResult = results[1];

      // 공격적 경력이 더 높은 생애 소득
      expect(
        aggressiveResult.totalLifetimeGross,
        greaterThan(conservativeResult.totalLifetimeGross),
      );

      // 공격적 경력이 더 높은 평균 소득
      expect(
        aggressiveResult.averageMonthlyIncome,
        greaterThan(conservativeResult.averageMonthlyIncome),
      );
    });
  });

  group('CareerSimulationEngine - Edge Cases', () {
    test('봉급표가 없는 경우', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '기본',
        events: [],
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => null); // 봉급표 없음

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then: 초기 기본급 유지
      final projection = result.yearlyProjections.first;
      expect(projection.baseSalary, 3000000); // 초기값 유지
    });

    test('빈 시나리오 (이벤트 없음)', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 3000000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '7급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '이벤트 없음',
        events: [],
      );

      final salaryTable = const SalaryTable(
        year: 2025,
        track: 'general',
        grades: {
          '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000},
          ),
        },
      );

      when(
        () => mockRepository.getSalaryTable(
          year: 2025,
          track: 'general',
        ),
      ).thenAnswer((_) async => salaryTable);

      // When
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1990,
        retirementYear: 2025,
      );

      // Then: 정상 동작
      expect(result.yearlyProjections.length, 1);
      expect(result.totalLifetimeGross, greaterThan(0));
    });
  });

  group('CareerSimulationEngine - 실전 시나리오', () {
    test('9급 신규 임용 → 30년 근무 → 정년퇴직', () async {
      final input = const SalaryInput(
        baseMonthlySalary: 2300000,
        workingDaysPerMonth: 21,
        allowances: {},
        annualBonus: 0,
        pensionContributionRate: 0.09,
        appointmentYear: 2025,
        track: SalaryTrack.general,
        gradeId: '9급',
        step: 1,
        isAutoCalculated: false,
      );

      final scenario = const CareerScenario(
        name: '일반적인 공무원 경력',
        events: [
          // 매년 정기승급
          StepIncrementEvent(year: 2026, increment: 1),
          StepIncrementEvent(year: 2027, increment: 1),

          // 7급 승진 (3년차)
          PromotionEvent(year: 2028, newGrade: '7급', newStep: 1),

          // 계속 정기승급...
          StepIncrementEvent(year: 2029, increment: 1),
          StepIncrementEvent(year: 2030, increment: 1),
        ],
      );

      // Mock: 간단한 봉급표 설정
      when(
        () => mockRepository.getSalaryTable(
          year: any(named: 'year'),
          track: any(named: 'track'),
        ),
      ).thenAnswer((invocation) async {
        final year = invocation.namedArguments[const Symbol('year')] as int;
        return SalaryTable(
          year: year,
          track: 'general',
          grades: const {
            '9급': GradeSteps(
            gradeId: '9급',
            gradeName: '9급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 2300000, 2: 2400000, 3: 2500000},
          ),
            '7급': GradeSteps(
            gradeId: '7급',
            gradeName: '7급',
            minStep: 1,
            maxStep: 25,
            steps: {1: 3000000, 2: 3100000, 3: 3200000},
          ),
          },
        );
      });

      // When: 6년 시뮬레이션
      final result = await engine.simulate(
        initialInput: input,
        scenario: scenario,
        birthYear: 1995,
        retirementYear: 2030,
      );

      // Then
      expect(result.yearlyProjections.length, 6);

      // 2025년: 9급 1호봉
      expect(result.yearlyProjections[0].grade, '9급');
      expect(result.yearlyProjections[0].step, 1);

      // 2028년: 7급으로 승진
      expect(result.yearlyProjections[3].grade, '7급');
      expect(result.yearlyProjections[3].step, 1);

      // 생애 소득 > 0
      expect(result.totalLifetimeGross, greaterThan(0));
      expect(result.totalLifetimeNet, greaterThan(0));
      expect(result.totalPensionContributions, greaterThan(0));

      // 평균 기준소득월액 계산 확인
      expect(result.averageMonthlyIncome, greaterThan(2300000));
    });
  });
}
