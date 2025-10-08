/// 성과상여금 등급 (교육공무원 기준)
///
/// 초등교사는 S/A/B 3등급 체계 (C등급 없음)
/// - S등급: 상위 30%, 5,102,970원 (2025년 기준)
/// - A등급: 중위 50%, 4,273,220원 (기본값)
/// - B등급: 하위 20%, 3,650,900원
enum PerformanceGrade {
  /// S등급 (상위 30%)
  /// 2025년 지급액: 5,102,970원
  S,

  /// A등급 (중위 50%, 기본값)
  /// 2025년 지급액: 4,273,220원
  A,

  /// B등급 (하위 20%)
  /// 2025년 지급액: 3,650,900원
  B,
}

/// PerformanceGrade 확장
extension PerformanceGradeExtension on PerformanceGrade {
  /// 등급별 2025년 지급액 (차등지급률 50% 기준)
  int get amount {
    switch (this) {
      case PerformanceGrade.S:
        return 5_102_970;
      case PerformanceGrade.A:
        return 4_273_220;
      case PerformanceGrade.B:
        return 3_650_900;
    }
  }

  /// 등급 이름
  String get displayName {
    switch (this) {
      case PerformanceGrade.S:
        return 'S등급';
      case PerformanceGrade.A:
        return 'A등급';
      case PerformanceGrade.B:
        return 'B등급';
    }
  }

  /// 등급 설명
  String get description {
    switch (this) {
      case PerformanceGrade.S:
        return '상위 30%';
      case PerformanceGrade.A:
        return '중위 50%';
      case PerformanceGrade.B:
        return '하위 20%';
    }
  }
}
