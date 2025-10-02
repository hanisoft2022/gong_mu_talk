import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/pension/domain/entities/pension_profile.dart';
import 'package:gong_mu_talk/features/pension/domain/services/pension_calculator.dart';

void main() {
  late PensionCalculator calculator;

  setUp(() {
    calculator = PensionCalculator();
  });

  group('PensionCalculator - calculateMonthlyPension', () {
    test('재직 20년 정년퇴직 - 기본 연금액 계산', () {
      // Given: 평균 기준소득월액 500만원, 재직 20년
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
      );

      // When
      final monthlyPension = calculator.calculateMonthlyPension(profile);

      // Then: 500만원 × 38% = 190만원
      expect(monthlyPension, equals(5000000 * 0.38));
      expect(monthlyPension, equals(1900000));
    });

    test('재직 25년 정년퇴직 - 지급률 48%', () {
      // Given: 재직 25년
      final profile = const PensionProfile(
        birthYear: 1960,
        appointmentYear: 2000,
        retirementYear: 2025,
        averageMonthlyIncome: 6000000,
        totalServiceYears: 25,
      );

      // When
      final monthlyPension = calculator.calculateMonthlyPension(profile);

      // Then: 지급률 = 38% + (25-20) × 2% = 48%
      // 600만원 × 48% = 288만원
      expect(monthlyPension, equals(6000000 * 0.48));
      expect(monthlyPension, equals(2880000));
    });

    test('재직 33년 이상 - 최대 지급률 76%', () {
      // Given: 재직 35년
      final profile = const PensionProfile(
        birthYear: 1955,
        appointmentYear: 1990,
        retirementYear: 2025,
        averageMonthlyIncome: 7000000,
        totalServiceYears: 35,
      );

      // When
      final monthlyPension = calculator.calculateMonthlyPension(profile);

      // Then: 최대 지급률 76%
      // 700만원 × 76% = 532만원
      expect(monthlyPension, equals(7000000 * 0.76));
      expect(monthlyPension, equals(5320000));
    });

    test('재직 15년 미만 - 재직연수 × 1.9% 적용', () {
      // Given: 재직 15년, 60세 정년퇴직
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2010,
        retirementYear: 2025, // 60세 정년
        averageMonthlyIncome: 4000000,
        totalServiceYears: 15,
      );

      // When
      final monthlyPension = calculator.calculateMonthlyPension(profile);

      // Then: 지급률 = 15 × 1.9% = 28.5%
      // 400만원 × 28.5% = 114만원
      expect(monthlyPension, closeTo(4000000 * 0.285, 1));
      expect(monthlyPension, closeTo(1140000, 1));
    });

    test('조기퇴직 3년 - 감액 15% 적용', () {
      // Given: 재직 20년, 57세 퇴직 (3년 조기)
      final profile = const PensionProfile(
        birthYear: 1968,
        appointmentYear: 2005,
        retirementYear: 2025, // 57세 퇴직
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
      );

      // When
      final monthlyPension = calculator.calculateMonthlyPension(profile);

      // Then: 500만원 × 38% × (1 - 15%) = 161.5만원
      expect(monthlyPension, equals(5000000 * 0.38 * 0.85));
      expect(monthlyPension, equals(1615000));
    });

    test('조기퇴직 5년 이상 - 최대 감액 25% 적용', () {
      // Given: 재직 25년, 53세 퇴직 (7년 조기, but 최대 감액 25%)
      final profile = const PensionProfile(
        birthYear: 1972,
        appointmentYear: 2000,
        retirementYear: 2025, // 53세 퇴직
        averageMonthlyIncome: 6000000,
        totalServiceYears: 25,
      );

      // When
      final monthlyPension = calculator.calculateMonthlyPension(profile);

      // Then: 600만원 × 48% × (1 - 25%) = 216만원
      // 7년 조기지만 최대 감액 25%만 적용
      expect(monthlyPension, equals(6000000 * 0.48 * 0.75));
      expect(monthlyPension, equals(2160000));
    });
  });

  group('PensionCalculator - calculatePension (전체 계산)', () {
    test('재직 20년 정년퇴직 - 전체 계산 결과 검증', () {
      // Given
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
        expectedLifespan: 85,
        inflationRate: 0.02,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      expect(result.monthlyPension, equals(1900000));
      expect(result.yearlyPension, equals(1900000 * 12));
      expect(result.paymentRate, equals(0.38));
      expect(result.earlyRetirementReduction, equals(0.0));
      expect(result.yearlyProjection.length, equals(25)); // 60세~85세

      // 첫 해 수급액 확인 (물가상승 미반영)
      final firstYear = result.yearlyProjection.first;
      expect(firstYear.year, equals(2025));
      expect(firstYear.age, equals(60));
      expect(firstYear.monthlyAmount, equals(1900000));
      expect(firstYear.yearlyAmount, equals(1900000 * 12));

      // 마지막 해 수급액 확인 (물가상승 반영)
      final lastYear = result.yearlyProjection.last;
      expect(lastYear.year, equals(2049)); // 2025 + 24
      expect(lastYear.age, equals(84));
      // 24년 후 물가상승: 1900000 × (1.02)^24
      final expectedAmount = 1900000 * 1.608437; // 약 1.6084
      expect(lastYear.monthlyAmount, closeTo(expectedAmount, 1000));
    });

    test('재직 25년 조기퇴직 - 감액 적용 검증', () {
      // Given: 재직 25년, 57세 퇴직 (3년 조기)
      final profile = const PensionProfile(
        birthYear: 1968,
        appointmentYear: 2000,
        retirementYear: 2025, // 57세
        averageMonthlyIncome: 6000000,
        totalServiceYears: 25,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      // 지급률: 38% + 5 × 2% = 48%
      // 감액률: 3년 × 5% = 15%
      // 실제 지급률: 48% × (1 - 15%) = 40.8%
      expect(result.paymentRate, closeTo(0.48, 0.0001));
      expect(result.earlyRetirementReduction, closeTo(0.15, 0.0001));
      expect(result.monthlyPension, equals(6000000 * 0.48 * 0.85));
      expect(result.monthlyPension, equals(2448000));
    });

    test('물가상승률 반영 - 연도별 수급액 증가 확인', () {
      // Given: 물가상승률 3%
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
        inflationRate: 0.03,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 5년 후 수급액 확인
      final fifthYear = result.yearlyProjection[5];
      final expectedAmount = 1900000 * 1.159274; // (1.03)^5 = 1.159274
      expect(fifthYear.monthlyAmount, closeTo(expectedAmount, 1000));

      // 10년 후 수급액 확인
      final tenthYear = result.yearlyProjection[10];
      final expectedAmount10 = 1900000 * 1.343916; // (1.03)^10
      expect(tenthYear.monthlyAmount, closeTo(expectedAmount10, 1000));
    });

    test('평생 총액 계산 - 누적 합계 검증', () {
      // Given
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
        expectedLifespan: 70, // 10년 수급
        inflationRate: 0.0, // 단순화
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 10년 × 연 수급액
      final expectedLifetime = 1900000 * 12 * 10;
      expect(result.lifetimeTotal, equals(expectedLifetime));
      expect(result.yearlyProjection.length, equals(10));
    });
  });

  group('PensionCalculator - 일시금 계산', () {
    test('재직 10년 미만 - 기여금 + 이자', () {
      // Given: 재직 8년, 평균 월급 400만원
      final profile = const PensionProfile(
        birthYear: 1975,
        appointmentYear: 2017,
        retirementYear: 2025,
        averageMonthlyIncome: 4000000,
        totalServiceYears: 8,
      );

      // When
      final result = calculator.calculatePension(profile);
      final lumpSum = result.lumpSumOption;

      // Then
      // 기여금: 400만원 × 12개월 × 8년 × 9% = 3,456만원
      final expectedContributions = 4000000 * 12 * 8 * 0.09;
      expect(lumpSum.returnedContributions, equals(expectedContributions));
      expect(lumpSum.returnedContributions, equals(34560000));

      // 이자: 3,456만원 × 3% × 8년 = 829.44만원
      final expectedInterest = expectedContributions * 0.03 * 8;
      expect(lumpSum.additionalAmount, closeTo(expectedInterest, 100));

      // 총액: 기여금 + 이자 = 42,854,400원
      expect(lumpSum.totalAmount, closeTo(42854400, 100));
      expect(
        lumpSum.description,
        contains('재직 10년 미만'),
      );
    });

    test('재직 10년 이상 20년 미만 - 기여금 × 1.5', () {
      // Given: 재직 15년, 평균 월급 500만원
      final profile = const PensionProfile(
        birthYear: 1970,
        appointmentYear: 2010,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 15,
      );

      // When
      final result = calculator.calculatePension(profile);
      final lumpSum = result.lumpSumOption;

      // Then
      // 기여금: 500만원 × 12개월 × 15년 × 9% = 8,100만원
      final expectedContributions = 5000000 * 12 * 15 * 0.09;
      expect(lumpSum.returnedContributions, equals(expectedContributions));
      expect(lumpSum.returnedContributions, equals(81000000));

      // 총액: 기여금 × 1.5 = 12,150만원
      expect(lumpSum.totalAmount, equals(expectedContributions * 1.5));
      expect(lumpSum.totalAmount, equals(121500000));

      // 추가 지급액: 4,050만원
      expect(lumpSum.additionalAmount, equals(40500000));
      expect(
        lumpSum.description,
        contains('재직 10년 이상'),
      );
    });

    test('재직 20년 이상 - 일시금 선택 불가', () {
      // Given: 재직 20년
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
      );

      // When
      final result = calculator.calculatePension(profile);
      final lumpSum = result.lumpSumOption;

      // Then: 일시금 0원 (선택 불가)
      expect(lumpSum.totalAmount, equals(0));
      expect(lumpSum.additionalAmount, equals(0));
      expect(
        lumpSum.description,
        contains('연금 수급 권장'),
      );

      // 기여금은 참고로 표시
      final expectedContributions = 5000000 * 12 * 20 * 0.09;
      expect(lumpSum.returnedContributions, equals(expectedContributions));
    });
  });

  group('PensionCalculator - 연금 vs 일시금 비교', () {
    test('재직 15년 - 손익분기 연령 계산', () {
      // Given: 재직 15년, 60세 정년퇴직
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2010,
        retirementYear: 2025, // 60세 정년
        averageMonthlyIncome: 5000000,
        totalServiceYears: 15,
        inflationRate: 0.0, // 단순화
      );

      // When
      final result = calculator.calculatePension(profile);
      final comparison = calculator.comparePensionVsLumpSum(
        profile: profile,
        pensionResult: result,
      );

      // Then
      // 일시금: 기여금 × 1.5
      // 기여금: 500만원 × 12 × 15 × 0.09 = 81,000,000
      // 일시금: 81,000,000 × 1.5 = 121,500,000
      expect(comparison.lumpSum, equals(121500000));

      // 연금: 월 142.5만원 (500만원 × 28.5%)
      expect(result.monthlyPension, closeTo(1425000, 1));

      // 손익분기: 일시금 ÷ 연 수급액 = 약 6년 후 (66세)
      // 101,250,000 ÷ (1,425,000 × 12) = 5.92년
      expect(comparison.breakEvenAge, lessThanOrEqualTo(67));
      expect(comparison.breakEvenAge, greaterThanOrEqualTo(65));

      // 연금 권장
      expect(comparison.recommendation, contains('연금 수급 권장'));
    });

    test('재직 20년 이상 - 일시금 선택 불가', () {
      // Given: 재직 20년
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
      );

      // When
      final result = calculator.calculatePension(profile);
      final comparison = calculator.comparePensionVsLumpSum(
        profile: profile,
        pensionResult: result,
      );

      // Then
      expect(comparison.lumpSum, equals(0));
      expect(comparison.breakEvenAge, equals(0));
      expect(
        comparison.recommendation,
        contains('연금 수급만 가능'),
      );
    });

    test('재직 10년 - 일시금 vs 연금 비교', () {
      // Given: 재직 10년, 60세 정년퇴직
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2015,
        retirementYear: 2025, // 60세 정년
        averageMonthlyIncome: 4000000,
        totalServiceYears: 10,
        inflationRate: 0.0,
      );

      // When
      final result = calculator.calculatePension(profile);
      final comparison = calculator.comparePensionVsLumpSum(
        profile: profile,
        pensionResult: result,
      );

      // Then
      // 일시금: 기여금 × 1.5
      // 기여금: 400만원 × 12 × 10 × 0.09 = 43,200,000
      // 일시금: 43,200,000 × 1.5 = 64,800,000
      expect(comparison.lumpSum, equals(64800000));

      // 연금: 월 76만원 (400만원 × 19%)
      expect(result.monthlyPension, equals(760000));

      // 손익분기: 약 7-8년 후
      expect(comparison.breakEvenAge, lessThanOrEqualTo(70));
      expect(comparison.breakEvenAge, greaterThanOrEqualTo(67));
    });
  });

  group('PensionCalculator - Edge Cases', () {
    test('재직 1년 - 최소 재직기간', () {
      // Given: 재직 1년, 60세 정년퇴직
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2024,
        retirementYear: 2025, // 60세 정년
        averageMonthlyIncome: 3000000,
        totalServiceYears: 1,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 지급률 1.9%
      expect(result.paymentRate, equals(0.019));
      expect(result.monthlyPension, equals(3000000 * 0.019));

      // 일시금: 기여금 + 이자
      final lumpSum = result.lumpSumOption;
      expect(lumpSum.totalAmount, greaterThan(0));
    });

    test('재직 50년 - 최대 재직기간', () {
      // Given: 재직 50년 (비현실적이지만 경계값 테스트)
      final profile = const PensionProfile(
        birthYear: 1955,
        appointmentYear: 1975,
        retirementYear: 2025,
        averageMonthlyIncome: 8000000,
        totalServiceYears: 50,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 최대 지급률 76% 적용
      expect(result.paymentRate, equals(0.76));
      expect(result.monthlyPension, equals(8000000 * 0.76));
    });

    test('평균 기준소득월액 0원 - Edge Case', () {
      // Given: 비정상적인 케이스
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 0,
        totalServiceYears: 20,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 연금액 0원
      expect(result.monthlyPension, equals(0));
      expect(result.yearlyPension, equals(0));
      expect(result.lifetimeTotal, equals(0));
    });

    test('예상 수명이 퇴직 연령보다 낮은 경우', () {
      // Given: 비정상적인 케이스 (60세 퇴직, 예상 수명 55세)
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
        expectedLifespan: 55,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 연금 수급 기간 0년
      expect(result.yearlyProjection.isEmpty, isTrue);
      expect(result.lifetimeTotal, equals(0));
    });

    test('물가상승률 음수 - 디플레이션 시나리오', () {
      // Given: 디플레이션 -2%
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
        expectedLifespan: 70,
        inflationRate: -0.02,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 연금액 점차 감소
      final firstYear = result.yearlyProjection.first;
      final lastYear = result.yearlyProjection.last;

      expect(firstYear.monthlyAmount, greaterThan(lastYear.monthlyAmount));
    });

    test('물가상승률 10% - 고인플레이션 시나리오', () {
      // Given: 고인플레이션 10%
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
        expectedLifespan: 70,
        inflationRate: 0.10,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then: 10년 후 약 2.5배 증가
      final tenthYear = result.yearlyProjection[9];
      final expectedAmount = 1900000 * 2.357947; // (1.1)^9
      expect(tenthYear.monthlyAmount, closeTo(expectedAmount, 10000));
    });
  });

  group('PensionCalculator - 참고사항 검증', () {
    test('참고사항에 필수 정보 포함 확인', () {
      // Given
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      expect(result.notes.isNotEmpty, isTrue);

      final notesText = result.notes.join('\n');
      expect(notesText, contains('재직기간'));
      expect(notesText, contains('20년'));
      expect(notesText, contains('평균 기준소득월액'));
      expect(notesText, contains('지급률'));
      expect(notesText, contains('38'));
      expect(notesText, contains('물가상승률'));
      expect(notesText, contains('예상 수명'));
    });

    test('조기퇴직 시 감액 정보 표시', () {
      // Given: 3년 조기퇴직
      final profile = const PensionProfile(
        birthYear: 1968,
        appointmentYear: 2005,
        retirementYear: 2025,
        averageMonthlyIncome: 5000000,
        totalServiceYears: 20,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      final notesText = result.notes.join('\n');
      expect(notesText, contains('조기퇴직 감액'));
      expect(notesText, contains('15%'));
      expect(notesText, contains('3년 조기'));
      expect(notesText, contains('실제 지급률'));
    });
  });

  group('PensionCalculator - 실제 시나리오', () {
    test('시나리오 1: 교사 30년 정년퇴직', () {
      // Given: 초등교사, 1965년생, 1995년 임용, 2025년 정년
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 1995,
        retirementYear: 2025,
        averageMonthlyIncome: 5500000,
        totalServiceYears: 30,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      // 지급률: 38% + 10 × 2% = 58%
      expect(result.paymentRate, closeTo(0.58, 0.0001));
      expect(result.monthlyPension, closeTo(5500000 * 0.58, 1));
      expect(result.monthlyPension, closeTo(3190000, 1));

      // 연금 수급만 가능
      expect(result.lumpSumOption.totalAmount, equals(0));
    });

    test('시나리오 2: 행정직 공무원 23년 정년퇴직', () {
      // Given: 행정직, 1965년생, 2002년 임용, 2025년 정년
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2002,
        retirementYear: 2025,
        averageMonthlyIncome: 4800000,
        totalServiceYears: 23,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      // 지급률: 38% + 3 × 2% = 44%
      expect(result.paymentRate, equals(0.44));
      expect(result.monthlyPension, equals(4800000 * 0.44));
      expect(result.monthlyPension, equals(2112000));
    });

    test('시나리오 3: 경찰관 25년 55세 명예퇴직', () {
      // Given: 경찰관, 1970년생, 2000년 임용, 2025년 명예퇴직 (5년 조기)
      final profile = const PensionProfile(
        birthYear: 1970,
        appointmentYear: 2000,
        retirementYear: 2025, // 55세
        averageMonthlyIncome: 5200000,
        totalServiceYears: 25,
      );

      // When
      final result = calculator.calculatePension(profile);

      // Then
      // 지급률: 38% + 5 × 2% = 48%
      // 조기퇴직 감액: 5년 × 5% = 25% (최대)
      expect(result.paymentRate, equals(0.48));
      expect(result.earlyRetirementReduction, equals(0.25));

      // 실제 지급률: 48% × 75% = 36%
      expect(result.monthlyPension, equals(5200000 * 0.48 * 0.75));
      expect(result.monthlyPension, equals(1872000));
    });

    test('시나리오 4: 신규 임용자 12년 중도퇴직', () {
      // Given: 2013년 임용, 2025년 중도퇴직 (12년), 60세 정년
      final profile = const PensionProfile(
        birthYear: 1965,
        appointmentYear: 2013,
        retirementYear: 2025, // 60세 정년
        averageMonthlyIncome: 4000000,
        totalServiceYears: 12,
      );

      // When
      final result = calculator.calculatePension(profile);
      final comparison = calculator.comparePensionVsLumpSum(
        profile: profile,
        pensionResult: result,
      );

      // Then
      // 지급률: 12 × 1.9% = 22.8%
      expect(result.paymentRate, closeTo(0.228, 0.0001));
      expect(result.monthlyPension, closeTo(4000000 * 0.228, 1));

      // 일시금 선택 가능: 기여금 × 1.5
      expect(result.lumpSumOption.totalAmount, greaterThan(0));

      // 손익분기 분석
      expect(comparison.breakEvenAge, greaterThan(0));
      expect(comparison.recommendation.isNotEmpty, isTrue);
    });
  });
}
