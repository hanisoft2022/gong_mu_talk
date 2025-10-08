/// 교직수당 가산금 종류
enum TeachingAllowanceBonus {
  /// 가산금 3: 보직교사 (15만원)
  headTeacher(
    displayName: '보직교사 (부장 등)',
    description: '부장교사 등 보직',
    amount: 150000,
    code: 'allowance3_head',
  ),

  /// 가산금 3: 특수교사 (12만원)
  specialEducation(
    displayName: '특수교사',
    description: '특수교육 담당 교사',
    amount: 120000,
    code: 'allowance3',
  ),

  /// 가산금 5: 특성화교사 (2.5만~5만원, 호봉별 차등)
  vocationalEducation(
    displayName: '특성화교사',
    description: '특성화고 근무 교사 (호봉별 2.5만~5만원)',
    amount: 25000, // 최소 금액
    code: 'allowance5',
  ),

  /// 가산금 6: 보건교사 (4만원)
  healthTeacher(
    displayName: '보건교사',
    description: '보건교사',
    amount: 40000,
    code: 'allowance6',
  ),

  /// 가산금 7: 겸직수당 (교장 10만, 교감 5만)
  concurrentPosition(
    displayName: '겸직수당',
    description: '병설유치원 원장/원감 겸임',
    amount: 50000, // 교감 기준
    code: 'allowance7',
  ),

  /// 가산금 8: 영양교사 (4만원)
  nutritionTeacher(
    displayName: '영양교사',
    description: '영양교사',
    amount: 40000,
    code: 'allowance8',
  ),

  /// 가산금 9: 사서교사 (3만원)
  librarian(
    displayName: '사서교사',
    description: '사서교사',
    amount: 30000,
    code: 'allowance9',
  ),

  /// 가산금 10: 전문상담교사 (3만원)
  counselor(
    displayName: '전문상담교사',
    description: '전문상담교사',
    amount: 30000,
    code: 'allowance10',
  );

  const TeachingAllowanceBonus({
    required this.displayName,
    required this.description,
    required this.amount,
    required this.code,
  });

  final String displayName;
  final String description;
  final int amount;
  final String code;
}
