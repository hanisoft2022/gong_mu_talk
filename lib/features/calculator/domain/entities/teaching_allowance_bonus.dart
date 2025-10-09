/// 교직수당 가산금 종류
enum TeachingAllowanceBonus {
  /// 가산금 1: 원로교사수당 (5만원)
  veteranTeacher(
    displayName: '원로교사 (30년 이상 + 55세 이상)',
    description: '교직수당 가산금 1',
    officialName: '교직수당(가산금1)',
    amount: 50000,
    code: 'allowance1',
  ),

  /// 가산금 2: 보직교사 (15만원)
  headTeacher(
    displayName: '보직교사 (부장교사)',
    description: '교직수당 가산금 2',
    officialName: '교직수당(가산금2)',
    amount: 150000,
    code: 'allowance2',
  ),

  /// 가산금 3: 특수교사 (12만원)
  specialEducation(
    displayName: '특수교사',
    description: '교직수당 가산금 3',
    officialName: '교직수당(가산금3)',
    amount: 120000,
    code: 'allowance3',
  ),

  /// 가산금 4: 담임교사 (20만원)
  homeroom(
    displayName: '담임교사',
    description: '교직수당 가산금 4',
    officialName: '교직수당(가산금4)',
    amount: 200000,
    code: 'allowance4',
  ),

  /// 가산금 5: 전문교과 (2.5만~5만원, 호봉별 차등)
  vocationalEducation(
    displayName: '특성화교사수당 (전문교과)',
    description: '교직수당 가산금 5',
    officialName: '교직수당(가산금5)',
    amount: 25000, // 최소 금액
    code: 'allowance5',
  ),

  /// 가산금 6: 보건교사 (4만원)
  healthTeacher(
    displayName: '보건교사',
    description: '교직수당 가산금 6',
    officialName: '교직수당(가산금6)',
    amount: 40000,
    code: 'allowance6',
  ),

  /// 가산금 7: 겸직수당 (교장 10만, 교감 5만)
  concurrentPosition(
    displayName: '겸임 교장·교감',
    description: '교직수당 가산금 7',
    officialName: '교직수당(가산금7)',
    amount: 50000, // 교감 기준
    code: 'allowance7',
  ),

  /// 가산금 8: 영양교사 (4만원)
  nutritionTeacher(
    displayName: '영양교사',
    description: '교직수당 가산금 8',
    officialName: '교직수당(가산금8)',
    amount: 40000,
    code: 'allowance8',
  ),

  /// 가산금 9: 사서교사 (3만원)
  librarian(
    displayName: '사서교사',
    description: '교직수당 가산금 9',
    officialName: '교직수당(가산금9)',
    amount: 30000,
    code: 'allowance9',
  ),

  /// 가산금 10: 전문상담교사 (3만원)
  counselor(
    displayName: '전문상담교사',
    description: '교직수당 가산금 10',
    officialName: '교직수당(가산금10)',
    amount: 30000,
    code: 'allowance10',
  );

  const TeachingAllowanceBonus({
    required this.displayName,
    required this.description,
    required this.officialName,
    required this.amount,
    required this.code,
  });

  final String displayName;
  final String description;
  final String officialName;
  final int amount;
  final String code;
}
