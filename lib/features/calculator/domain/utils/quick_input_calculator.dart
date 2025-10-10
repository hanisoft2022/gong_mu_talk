/// 빠른 입력 계산기 유틸리티
///
/// QuickInputBottomSheet에서 사용하는 재직연수 및 교육경력 계산 로직을 제공합니다.
/// 순수 계산 함수들로 구성되어 테스트와 재사용이 용이합니다.
class QuickInputCalculator {
  /// 재직연수 계산 (년, 개월)
  ///
  /// 호봉 기반 순수 계산만 수행 (추가/제외 경력 미반영)
  /// 정근수당 계산 기준
  ///
  /// [currentGrade] 현재 호봉
  /// [hasFirstGradeCertificate] 1급 정교사 자격증 소지 여부
  /// [gradePromotionMonth] 호봉 승급월 (1-12)
  ///
  /// Returns: {'years': int, 'months': int}
  static Map<String, int> calculateServiceYears({
    required int currentGrade,
    required bool hasFirstGradeCertificate,
    required int gradePromotionMonth,
  }) {
    final now = DateTime.now();

    // 기본 연수 (호봉 - 9 - 1급 정교사 가산)
    final baseYears = currentGrade - 9 - (hasFirstGradeCertificate ? 1 : 0);

    // 승급월 고려한 개월 수
    final thisYearPromotion = DateTime(now.year, gradePromotionMonth, 1);
    int totalMonths;

    if (now.isBefore(thisYearPromotion)) {
      // 아직 승급 안 됨
      final lastPromotion = DateTime(now.year - 1, gradePromotionMonth, 1);
      final monthsSincePromotion =
          (now.year - lastPromotion.year) * 12 + (now.month - lastPromotion.month);
      totalMonths = ((baseYears - 1) * 12) + monthsSincePromotion;
    } else {
      // 승급 완료
      final monthsSincePromotion =
          (now.year - thisYearPromotion.year) * 12 + (now.month - thisYearPromotion.month);
      totalMonths = (baseYears * 12) + monthsSincePromotion;
    }

    if (totalMonths < 0) totalMonths = 0;

    return {'years': totalMonths ~/ 12, 'months': totalMonths % 12};
  }

  /// 교육경력 계산 (년, 개월)
  ///
  /// 재직연수 + 추가 - 제외 반영
  /// 교원연구비 계산 기준
  ///
  /// [currentGrade] 현재 호봉
  /// [hasFirstGradeCertificate] 1급 정교사 자격증 소지 여부
  /// [gradePromotionMonth] 호봉 승급월 (1-12)
  /// [additionalTeachingMonths] 추가 교육경력 (개월)
  /// [excludedTeachingMonths] 제외 교육경력 (개월)
  ///
  /// Returns: {'years': int, 'months': int}
  static Map<String, int> calculateTeachingExperience({
    required int currentGrade,
    required bool hasFirstGradeCertificate,
    required int gradePromotionMonth,
    required int additionalTeachingMonths,
    required int excludedTeachingMonths,
  }) {
    final now = DateTime.now();

    // 기본 연수 (호봉 - 9 - 1급 정교사 가산)
    final baseYears = currentGrade - 9 - (hasFirstGradeCertificate ? 1 : 0);

    // 승급월 고려한 개월 수
    final thisYearPromotion = DateTime(now.year, gradePromotionMonth, 1);
    int totalMonths;

    if (now.isBefore(thisYearPromotion)) {
      // 아직 승급 안 됨
      final lastPromotion = DateTime(now.year - 1, gradePromotionMonth, 1);
      final monthsSincePromotion =
          (now.year - lastPromotion.year) * 12 + (now.month - lastPromotion.month);
      totalMonths = ((baseYears - 1) * 12) + monthsSincePromotion;
    } else {
      // 승급 완료
      final monthsSincePromotion =
          (now.year - thisYearPromotion.year) * 12 + (now.month - thisYearPromotion.month);
      totalMonths = (baseYears * 12) + monthsSincePromotion;
    }

    // 추가/제외 반영
    totalMonths = totalMonths + additionalTeachingMonths - excludedTeachingMonths;
    if (totalMonths < 0) totalMonths = 0;

    return {'years': totalMonths ~/ 12, 'months': totalMonths % 12};
  }

  /// 퇴직 연령 최소값 계산
  ///
  /// 명예퇴직 가능 최소 연령 = max(20년 재직 시 나이, 현재 나이)
  ///
  /// [birthYear] 출생 연도
  /// [birthMonth] 출생 월
  /// [employmentStartDate] 임용일
  ///
  /// Returns: 퇴직 가능 최소 연령
  static int calculateMinRetirementAge({
    required int birthYear,
    required int birthMonth,
    required DateTime employmentStartDate,
  }) {
    // 1. 임용일 + 20년 → 명예퇴직 최소 시점
    final twentyYearsAfterEmployment = DateTime(
      employmentStartDate.year + 20,
      employmentStartDate.month,
      employmentStartDate.day,
    );

    // 2. 명예퇴직 최소 시점의 나이 계산
    final ageAt20YearsService = twentyYearsAfterEmployment.year - birthYear;

    // 3. 현재 나이 계산
    final currentAge = DateTime.now().year - birthYear;

    // 4. 최소 퇴직 가능 연령 = max(20년 재직 시 나이, 현재 나이)
    return ageAt20YearsService > currentAge ? ageAt20YearsService : currentAge;
  }

  /// 퇴직 연령 설명 텍스트 생성
  ///
  /// [retirementAge] 선택된 퇴직 연령
  ///
  /// Returns: {'description': String, 'type': 'early' | 'standard' | 'extended'}
  static Map<String, String> getRetirementAgeDescription(int retirementAge) {
    if (retirementAge < 62) {
      return {
        'description': '명예퇴직 (재직 20년 이상)',
        'type': 'early',
      };
    } else if (retirementAge == 62) {
      return {
        'description': '현행 법정 정년 (62세)',
        'type': 'standard',
      };
    } else {
      return {
        'description': '정년 연장 시나리오 (정부 논의 단계, 법 개정 전)',
        'type': 'extended',
      };
    }
  }
}
