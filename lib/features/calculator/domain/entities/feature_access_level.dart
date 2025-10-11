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
  /// - 계산기: 모든 카드 접근 가능 (블러 전략)
  ///   * 현재급여 카드: 카드는 보임, 상세 페이지 접근 가능하나 전체 블러 처리
  ///   * 퇴직일시금 카드: 카드는 보임, 상세 페이지 접근 가능하나 전체 블러 처리
  ///   * 연금 카드: 카드는 보이나 숫자 블러 처리, 상세 페이지 접근 가능하나 전체 블러 처리
  ///   * 메시지: "로그인 + 인증 후 이용 가능"
  guest(0, '비회원'),

  /// Level 1: 회원 (로그인만 완료)
  /// - 라운지: 읽기만 가능
  /// - 계산기: 일부 기능 제한 (블러 전략)
  ///   * 현재급여 카드: 숫자 공개, 상세 페이지 접근 가능 (단, Tab 4 생애 시뮬레이션 블러)
  ///   * 퇴직일시금 카드: 숫자 공개, 상세 페이지 접근 가능하나 블러 처리
  ///   * 연금 카드: 카드는 보이나 숫자 블러 처리, 상세 페이지 접근 가능하나 블러 처리
  ///   * 메시지: "인증 후 이용 가능"
  member(1, '회원'),

  /// Level 2: 공직자 메일 인증 완료
  /// - 라운지: 글/댓글 작성 가능
  /// - 계산기: 대부분 기능 공개 (연금 상세는 제외)
  ///   * 현재급여 카드: 완전 공개 (상세 분석 + Tab 4 생애 시뮬레이션 모두 접근 가능)
  ///   * 퇴직일시금 카드: 완전 공개 (상세 분석 접근 가능)
  ///   * 연금 카드: 숫자만 공개 (카드에서 월 실수령액, 수령 기간 등 확인 가능)
  ///   * 연금 상세 페이지: 접근 가능하나 블러 처리 (직렬 인증 필요)
  ///   * 중요: 연금 카드와 연금 상세 페이지는 구분됨
  emailVerified(2, '공직자 메일 인증'),

  /// Level 3: 직렬 인증 완료
  /// - 라운지: Level 2 + 전문 라운지 접근 (직렬별)
  /// - 계산기: 모든 기능 완전 공개
  ///   * 현재급여 카드: 완전 공개
  ///   * 퇴직일시금 카드: 완전 공개
  ///   * 연금 카드: 완전 공개 (카드 숫자 + 상세 페이지 모두 접근 가능)
  ///   * Level 2와의 핵심 차이: 연금 상세 분석 페이지 접근 가능 (블러 없음)
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
