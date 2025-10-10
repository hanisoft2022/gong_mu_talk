/// 기능 접근 레벨 정의
///
/// 앱 전체에서 사용되는 인증 기반 접근 제어 레벨
/// 숫자가 클수록 높은 권한
///
/// 사용 예시:
/// ```dart
/// if (authState.currentAccessLevel >= FeatureAccessLevel.emailVerified) {
///   // 공직자 메일 인증이 완료된 사용자만 접근 가능
/// }
/// ```
enum FeatureAccessLevel {
  /// Level 0: 비회원 (게스트)
  /// - 라운지: 읽기만 가능
  /// - 계산기: 요약 수치만 표시
  guest(0, '비회원'),

  /// Level 1: 회원 (로그인만 완료)
  /// - 라운지: 읽기만 가능
  /// - 계산기: 요약 수치만 표시
  member(1, '회원'),

  /// Level 2: 공직자 메일 인증 완료
  /// - 라운지: 글/댓글 작성 가능
  /// - 계산기: 상세 분석, 5-10년 시뮬레이션 가능
  emailVerified(2, '공직자 메일 인증'),

  /// Level 3: 직렬 인증 완료
  /// - 라운지: Level 2 + 전문 라운지 접근
  /// - 계산기: Level 2 + 30년 생애 시뮬레이션, 차트 분석
  /// - 주의: 직렬 인증 완료 시 공직자 메일 인증 권한 자동 포함 (OR 로직)
  careerVerified(3, '직렬 인증');

  const FeatureAccessLevel(this.level, this.displayName);

  /// 숫자 레벨 (0-3)
  final int level;

  /// 화면 표시용 이름
  final String displayName;

  /// 레벨 비교 연산자
  bool operator >=(FeatureAccessLevel other) => level >= other.level;
  bool operator >(FeatureAccessLevel other) => level > other.level;
  bool operator <=(FeatureAccessLevel other) => level <= other.level;
  bool operator <(FeatureAccessLevel other) => level < other.level;

  /// 다음 레벨 가져오기
  FeatureAccessLevel? get nextLevel {
    switch (this) {
      case FeatureAccessLevel.guest:
        return FeatureAccessLevel.member;
      case FeatureAccessLevel.member:
        return FeatureAccessLevel.emailVerified;
      case FeatureAccessLevel.emailVerified:
        return FeatureAccessLevel.careerVerified;
      case FeatureAccessLevel.careerVerified:
        return null; // 최고 레벨
    }
  }

  /// 다음 레벨로 가기 위한 액션 설명
  String get nextLevelActionDescription {
    switch (this) {
      case FeatureAccessLevel.guest:
        return '회원가입이 필요합니다';
      case FeatureAccessLevel.member:
        return '공직자 메일 인증이 필요합니다';
      case FeatureAccessLevel.emailVerified:
        return '직렬 인증이 필요합니다';
      case FeatureAccessLevel.careerVerified:
        return '최고 레벨입니다';
    }
  }

  /// 인증 페이지 라우트 경로
  String? get verificationRoute {
    switch (this) {
      case FeatureAccessLevel.guest:
      case FeatureAccessLevel.member:
        return '/profile'; // 프로필 페이지에서 인증 카드 표시
      case FeatureAccessLevel.emailVerified:
        return '/profile'; // 직렬 인증도 프로필 페이지
      case FeatureAccessLevel.careerVerified:
        return null;
    }
  }
}
