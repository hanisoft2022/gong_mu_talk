/// String 확장 메서드들
library;
extension StringExtensions on String {
  /// 문자열이 비어있지 않은지 확인
  bool get isNotNullOrEmpty => isNotEmpty;

  /// 문자열이 null이거나 비어있는지 확인
  bool get isNullOrEmpty => isEmpty;

  /// 첫 글자를 대문자로 변환
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 텍스트 줄바꿈 처리
  String get withLineBreaks => replaceAll('\\n', '\n');

  /// HTML 태그 제거
  String get stripHtml => replaceAll(RegExp(r'<[^>]*>'), '');

  /// 텍스트 트림 및 다중 공백 제거
  String get cleanWhitespace => trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// null 가능한 String 확장 메서드들
extension NullableStringExtensions on String? {
  /// null이거나 비어있는지 확인
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// null이 아니고 비어있지 않은지 확인
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// null일 경우 빈 문자열 반환
  String get orEmpty => this ?? '';

  /// null일 경우 기본값 반환
  String orDefault(String defaultValue) => this ?? defaultValue;
}