/// 교사 직급
enum Position {
  /// 교사
  teacher('교사'),

  /// 보직교사
  headTeacher('보직교사'),

  /// 수석교사
  seniorTeacher('수석교사'),

  /// 교감
  vicePrincipal('교감'),

  /// 교장
  principal('교장');

  const Position(this.displayName);

  final String displayName;
}
