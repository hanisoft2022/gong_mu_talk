import 'package:equatable/equatable.dart';

/// 수당 기준표
/// 특정 연도의 법정 수당 기준액
class AllowanceStandard extends Equatable {
  const AllowanceStandard({
    required this.year,
    required this.standards,
    this.metadata = const {},
  });

  /// 적용 연도
  final int year;

  /// 수당별 기준액
  final Map<AllowanceType, double> standards;

  /// 메타데이터
  final Map<String, dynamic> metadata;

  /// 특정 수당의 기준액 조회
  double? getStandard(AllowanceType type) => standards[type];

  @override
  List<Object?> get props => [year, standards, metadata];
}

/// 수당 종류
enum AllowanceType {
  /// 정액급식비
  mealAllowance('정액급식비'),

  /// 교통보조비 (직급보조비)
  transportationAllowance('교통보조비'),

  /// 명절휴가비
  holidayBonus('명절휴가비'),

  /// 정근수당 (연 2회)
  longevityAllowance('정근수당'),

  /// 성과상여금
  performanceBonus('성과상여금'),

  /// 가족수당 (배우자)
  familyAllowanceSpouse('가족수당(배우자)'),

  /// 가족수당 (자녀 1인)
  familyAllowanceChild('가족수당(자녀)'),

  /// 가족수당 (부모)
  familyAllowanceParent('가족수당(부모)'),

  /// 시간외근무수당 (기본 시간당)
  overtimeAllowanceHourly('시간외근무수당'),

  /// 야간근무수당
  nightDutyAllowance('야간근무수당'),

  /// 위험근무수당
  hazardAllowance('위험근무수당'),

  /// 특수업무수당
  specialDutyAllowance('특수업무수당');

  const AllowanceType(this.displayName);
  final String displayName;
}

/// 2025년 수당 기준표 샘플
class AllowanceStandardSamples {
  /// 2025년 일반직 공무원 수당 기준
  static AllowanceStandard general2025() {
    return const AllowanceStandard(
      year: 2025,
      standards: {
        // 정액급식비: 월 140,000원
        AllowanceType.mealAllowance: 140000,

        // 교통보조비: 월 200,000원 (일반직 기준)
        AllowanceType.transportationAllowance: 200000,

        // 명절휴가비: 기본급의 60% × 2회
        // (실제 계산 시 기본급 기준으로 별도 계산)
        AllowanceType.holidayBonus: 0, // 기본급 대비 비율로 계산

        // 정근수당: 기본급의 5% × 2회
        // (실제 계산 시 기본급 기준으로 별도 계산)
        AllowanceType.longevityAllowance: 0, // 기본급 대비 비율로 계산

        // 가족수당
        AllowanceType.familyAllowanceSpouse: 40000,    // 배우자
        AllowanceType.familyAllowanceChild: 30000,     // 자녀 1인당
        AllowanceType.familyAllowanceParent: 30000,    // 부모 1인당
      },
      metadata: {
        'source': '인사혁신처',
        'updatedAt': '2025-01-01',
        'description': '2025년 일반직공무원 수당 기준',
        'notes': [
          '명절휴가비: 기본급의 60% × 연 2회',
          '정근수당: 기본급 × 5% × 연 2회 (5년 미만)',
          '정근수당: 기본급 × 연차에 따라 증가 (5년 이상)',
        ],
      },
    );
  }
}

/// 정근수당 지급률 계산
class LongevityAllowanceCalculator {
  /// 근속연수에 따른 정근수당 지급률 (연간 지급액 / 기본급)
  /// 연 2회 지급 기준
  /// 
  /// 근속기간별 지급률:
  /// - 5년 미만: 기본급 × 5% × 2회 = 10%
  /// - 5~10년 미만: 기본급 × 10% × 2회 = 20%
  /// - 10~15년 미만: 기본급 × 15% × 2회 = 30%
  /// - 15~20년 미만: 기본급 × 20% × 2회 = 40%
  /// - 20년 이상: 기본급 × 25% × 2회 = 50%
  static double getAnnualRate(int serviceYears) {
    if (serviceYears < 5) {
      return 0.10; // 5% × 2회
    } else if (serviceYears < 10) {
      return 0.20; // 10% × 2회
    } else if (serviceYears < 15) {
      return 0.30; // 15% × 2회
    } else if (serviceYears < 20) {
      return 0.40; // 20% × 2회
    } else {
      return 0.50; // 25% × 2회
    }
  }

  /// 정근수당 연간 지급액 계산
  static double calculateAnnualAmount({
    required double baseSalary,
    required int serviceYears,
  }) {
    final rate = getAnnualRate(serviceYears);
    return baseSalary * rate;
  }
}

/// 명절휴가비 계산
class HolidayBonusCalculator {
  /// 명절휴가비 연간 지급액 계산
  /// 기본급 × 60% × 2회 (설날, 추석)
  static double calculateAnnualAmount(double baseSalary) {
    return baseSalary * 0.60 * 2;
  }
}

/// 성과상여금 계산
class PerformanceBonusCalculator {
  /// 성과상여금 등급별 지급률
  /// S등급: 기본급 × 150%
  /// A등급: 기본급 × 120%
  /// B등급: 기본급 × 100%
  /// C등급: 기본급 × 80%
  static double getRate(String grade) {
    switch (grade.toUpperCase()) {
      case 'S':
        return 1.50;
      case 'A':
        return 1.20;
      case 'B':
        return 1.00;
      case 'C':
        return 0.80;
      default:
        return 1.00;
    }
  }

  /// 성과상여금 연간 지급액 계산
  static double calculateAnnualAmount({
    required double baseSalary,
    required String grade,
  }) {
    final rate = getRate(grade);
    return baseSalary * rate;
  }
}
