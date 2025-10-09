/// 학교급 (교원연구비 산정용)
enum SchoolType {
  /// 유·초등
  elementary('유·초등'),

  /// 중등
  secondary('중등');

  const SchoolType(this.displayName);

  final String displayName;
}
