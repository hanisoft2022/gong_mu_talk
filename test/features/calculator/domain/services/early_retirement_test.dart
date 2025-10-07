import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/early_retirement_calculation_service.dart';

void main() {
  late EarlyRetirementCalculationService service;

  setUp(() {
    service = EarlyRetirementCalculationService();
  });

  group('EarlyRetirementCalculationService', () {
    group('calculateEarlyRetirementBonus', () {
      test('55세 명퇴 (10년 잔여)', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1970,
          birthMonth: 3,
          currentGrade: 30,
          position: Position.teacher,
          employmentStartDate: DateTime(2000, 3, 1),
          retirementAge: 65,
        );

        final earlyRetirementDate = DateTime(2025, 3, 1); // 55세

        // Act
        final result = service.calculateEarlyRetirementBonus(
          profile: profile,
          earlyRetirementDate: earlyRetirementDate,
        );

        // Assert
        expect(result.remainingYears, greaterThan(5));
        expect(result.baseAmount, greaterThan(0));
        expect(result.bonusAmount, greaterThan(0));
        expect(
          result.totalAmount,
          equals(result.baseAmount + result.bonusAmount),
        );
      });

      test('58세 명퇴 (7년 잔여)', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1967,
          birthMonth: 3,
          currentGrade: 25,
          position: Position.teacher,
          employmentStartDate: DateTime(1997, 3, 1),
          retirementAge: 65,
        );

        final earlyRetirementDate = DateTime(2025, 3, 1); // 58세

        // Act
        final result = service.calculateEarlyRetirementBonus(
          profile: profile,
          earlyRetirementDate: earlyRetirementDate,
        );

        // Assert
        expect(result.remainingYears, greaterThanOrEqualTo(5));
        expect(result.baseAmount, greaterThan(0));
        expect(result.bonusAmount, greaterThan(0));
        expect(result.totalAmount, greaterThan(result.baseAmount));
      });

      test('60세 명퇴 (5년 잔여)', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1965,
          birthMonth: 3,
          currentGrade: 20,
          position: Position.teacher,
          employmentStartDate: DateTime(1995, 3, 1),
          retirementAge: 65,
        );

        final earlyRetirementDate = DateTime(2025, 3, 1); // 60세

        // Act
        final result = service.calculateEarlyRetirementBonus(
          profile: profile,
          earlyRetirementDate: earlyRetirementDate,
        );

        // Assert
        expect(result.remainingYears, greaterThanOrEqualTo(3));
        expect(result.baseAmount, greaterThan(0));
        expect(result.bonusAmount, greaterThan(0));
        expect(result.totalAmount, greaterThan(result.baseAmount));
      });

      test('64세 명퇴 (1년 잔여)', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1961,
          birthMonth: 3,
          currentGrade: 18,
          position: Position.teacher,
          employmentStartDate: DateTime(1991, 3, 1),
          retirementAge: 65,
        );

        final earlyRetirementDate = DateTime(2025, 3, 1); // 64세

        // Act
        final result = service.calculateEarlyRetirementBonus(
          profile: profile,
          earlyRetirementDate: earlyRetirementDate,
        );

        // Assert
        expect(result.remainingYears, greaterThanOrEqualTo(0));
        expect(result.totalAmount, greaterThanOrEqualTo(0));
      });

      test('정년 퇴직 (명퇴금 0)', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1960,
          birthMonth: 3,
          currentGrade: 15,
          position: Position.teacher,
          employmentStartDate: DateTime(1990, 3, 1),
        );

        final regularRetirementDate = profile.calculateRetirementDate();

        // Act
        final result = service.calculateEarlyRetirementBonus(
          profile: profile,
          earlyRetirementDate: regularRetirementDate,
        );

        // Assert
        expect(result.remainingYears, 0);
        expect(result.remainingMonths, 0);
        expect(result.totalAmount, 0);
      });

      test('명퇴 날짜 미지정 시 현재 기준 계산', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1970,
          birthMonth: 3,
          currentGrade: 30,
          position: Position.teacher,
          employmentStartDate: DateTime(2000, 3, 1),
        );

        // Act
        final result = service.calculateEarlyRetirementBonus(
          profile: profile,
          // earlyRetirementDate 미지정
        );

        // Assert
        expect(result.remainingYears, greaterThanOrEqualTo(0));
        expect(result.baseAmount, greaterThanOrEqualTo(0));
      });
    });

    group('compareEarlyRetirementScenarios', () {
      test('여러 명퇴 시나리오 비교', () {
        // Arrange
        final profile = TeacherProfile(
          birthYear: 1970,
          birthMonth: 3,
          currentGrade: 30,
          position: Position.teacher,
          employmentStartDate: DateTime(2000, 3, 1),
        );

        // Act
        final results = service.compareEarlyRetirementScenarios(
          profile: profile,
          startAge: 55,
          endAge: 64,
        );

        // Assert
        expect(results.isNotEmpty, true);

        // 모든 시나리오 검증
        for (final scenario in results) {
          expect(scenario.retirementAge, greaterThanOrEqualTo(55));
          expect(scenario.retirementAge, lessThan(65));
        }

        // 잔여기간이 긴 초기 명퇴일수록 명퇴금 많음
        if (results.length >= 2) {
          expect(
            results.first.totalAmount,
            greaterThan(results.last.totalAmount),
          );
        }
      });
    });

    group('calculateMonthlyAccumulation', () {
      test('월별 적립액 계산', () {
        // Arrange
        const totalAmount = 36000000;
        const remainingMonths = 60;

        // Act
        final result = service.calculateMonthlyAccumulation(
          totalAmount: totalAmount,
          remainingMonths: remainingMonths,
        );

        // Assert
        expect(result, equals(600000));
      });

      test('잔여개월이 0인 경우', () {
        // Arrange
        const totalAmount = 36000000;
        const remainingMonths = 0;

        // Act
        final result = service.calculateMonthlyAccumulation(
          totalAmount: totalAmount,
          remainingMonths: remainingMonths,
        );

        // Assert
        expect(result, 0);
      });
    });

    group('compareEarlyVsRegularRetirement', () {
      test('명퇴 vs 정년 총 수령액 비교', () {
        // Arrange
        const earlyRetirementBonus = 50000000;
        const earlyRetirementPension = 2000000;
        const regularRetirementPension = 2500000;
        const remainingYears = 5;
        const retirementAge = 60;

        // Act
        final result = service.compareEarlyVsRegularRetirement(
          earlyRetirementBonus: earlyRetirementBonus,
          earlyRetirementPension: earlyRetirementPension,
          regularRetirementPension: regularRetirementPension,
          remainingYears: remainingYears,
          retirementAge: retirementAge,
        );

        // Assert
        expect(result['earlyTotal'], greaterThan(0));
        expect(result['regularTotal'], greaterThan(0));
        expect(result['difference'], isNotNull);
      });
    });
  });
}
