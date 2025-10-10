part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isLoggedIn = false,
    this.isProcessing = false,
    this.isAuthenticating = false,
    this.isGovernmentEmailVerificationInProgress = false,
    this.isEmailVerified = false,
    this.isPasswordProvider = true,
    this.userProfile,
    this.careerTrack = CareerTrack.none,
    this.nickname = '공무원',
    this.handle = '',
    this.serial = 'unknown',
    this.department = 'unknown',
    this.region = 'unknown',
    this.jobTitle = '직무 미입력',
    this.yearsOfService = 0,
    this.bio,
    this.photoUrl,
    this.nicknameChangeCount = 0,
    this.nicknameLastChangedAt,
    this.nicknameResetAt,
    this.extraNicknameTickets = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.notificationsEnabled = true,
    this.serialVisible = true,
    this.excludedTracks = const <CareerTrack>{},
    this.excludedSerials = const <String>{},
    this.excludedDepartments = const <String>{},
    this.excludedRegions = const <String>{},
    this.userId,
    this.email,
    this.primaryEmail,
    this.authError,
    this.lastMessage,
    this.careerHierarchy,
  });

  final bool isLoggedIn;
  final bool isProcessing;
  final bool isAuthenticating;
  final bool isGovernmentEmailVerificationInProgress;
  final bool isEmailVerified;
  final bool isPasswordProvider; // true if email/password, false if Google/etc
  final UserProfile? userProfile;
  final CareerTrack careerTrack;
  final String nickname;
  final String handle;
  final String serial;
  final String department;
  final String region;
  final String jobTitle;
  final int yearsOfService;
  final String? bio;
  final String? photoUrl;
  final int nicknameChangeCount;
  final DateTime? nicknameLastChangedAt;
  final DateTime? nicknameResetAt;
  final int extraNicknameTickets;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool notificationsEnabled;
  final bool serialVisible;
  final Set<CareerTrack> excludedTracks;
  final Set<String> excludedSerials;
  final Set<String> excludedDepartments;
  final Set<String> excludedRegions;
  final String? userId;
  final String? email;
  final String? primaryEmail;
  final String? authError;
  final String? lastMessage;
  final CareerHierarchy? careerHierarchy;

  static const Object _unset = Object();

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isProcessing,
    bool? isAuthenticating,
    bool? isGovernmentEmailVerificationInProgress,
    bool? isEmailVerified,
    bool? isPasswordProvider,
    UserProfile? userProfile,
    CareerTrack? careerTrack,
    String? nickname,
    String? handle,
    String? serial,
    String? department,
    String? region,
    String? jobTitle,
    int? yearsOfService,
    String? bio,
    String? photoUrl,
    int? nicknameChangeCount,
    DateTime? nicknameLastChangedAt,
    DateTime? nicknameResetAt,
    int? extraNicknameTickets,
    int? followerCount,
    int? followingCount,
    int? postCount,
    bool? notificationsEnabled,
    bool? serialVisible,
    Set<CareerTrack>? excludedTracks,
    Set<String>? excludedSerials,
    Set<String>? excludedDepartments,
    Set<String>? excludedRegions,
    Object? userId = _unset,
    Object? email = _unset,
    Object? primaryEmail = _unset,
    Object? authError = _unset,
    Object? lastMessage = _unset,
    Object? careerHierarchy = _unset,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isProcessing: isProcessing ?? this.isProcessing,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isGovernmentEmailVerificationInProgress:
          isGovernmentEmailVerificationInProgress ??
          this.isGovernmentEmailVerificationInProgress,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPasswordProvider: isPasswordProvider ?? this.isPasswordProvider,
      userProfile: userProfile ?? this.userProfile,
      careerTrack: careerTrack ?? this.careerTrack,
      nickname: nickname ?? this.nickname,
      handle: handle ?? this.handle,
      serial: serial ?? this.serial,
      department: department ?? this.department,
      region: region ?? this.region,
      jobTitle: jobTitle ?? this.jobTitle,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      nicknameChangeCount: nicknameChangeCount ?? this.nicknameChangeCount,
      nicknameLastChangedAt:
          nicknameLastChangedAt ?? this.nicknameLastChangedAt,
      nicknameResetAt: nicknameResetAt ?? this.nicknameResetAt,
      extraNicknameTickets: extraNicknameTickets ?? this.extraNicknameTickets,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      serialVisible: serialVisible ?? this.serialVisible,
      excludedTracks: excludedTracks ?? this.excludedTracks,
      excludedSerials: excludedSerials ?? this.excludedSerials,
      excludedDepartments: excludedDepartments ?? this.excludedDepartments,
      excludedRegions: excludedRegions ?? this.excludedRegions,
      userId: userId == _unset ? this.userId : userId as String?,
      email: email == _unset ? this.email : email as String?,
      primaryEmail: primaryEmail == _unset
          ? this.primaryEmail
          : primaryEmail as String?,
      authError: authError == _unset ? this.authError : authError as String?,
      lastMessage: lastMessage == _unset
          ? this.lastMessage
          : lastMessage as String?,
      careerHierarchy: careerHierarchy == _unset
          ? this.careerHierarchy
          : careerHierarchy as CareerHierarchy?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoggedIn,
    isProcessing,
    isAuthenticating,
    isGovernmentEmailVerificationInProgress,
    isEmailVerified,
    isPasswordProvider,
    userProfile,
    careerTrack,
    nickname,
    handle,
    serial,
    department,
    region,
    jobTitle,
    yearsOfService,
    bio,
    photoUrl,
    nicknameChangeCount,
    nicknameLastChangedAt,
    nicknameResetAt,
    extraNicknameTickets,
    followerCount,
    followingCount,
    postCount,
    notificationsEnabled,
    serialVisible,
    excludedTracks,
    excludedSerials,
    excludedDepartments,
    excludedRegions,
    userId,
    email,
    primaryEmail,
    authError,
    lastMessage,
    careerHierarchy,
  ];

  String? get preferredEmail => primaryEmail ?? email;

  bool get isGovernmentEmail {
    final String? currentEmail = email;
    if (currentEmail == null) {
      return false;
    }
    final String normalized = currentEmail.trim().toLowerCase();
    // 임시로 @naver.com 도메인도 허용
    return normalized.endsWith('@korea.kr') ||
        normalized.endsWith('.go.kr') ||
        normalized.endsWith('@naver.com');
  }

  bool get isGovernmentEmailVerified =>
      userProfile?.isGovernmentEmailVerified ?? false;

  bool get isCareerTrackVerified =>
      userProfile?.isCareerTrackVerified ?? false;

  bool get hasNicknameTickets => extraNicknameTickets > 0;

  bool get canChangeNickname {
    // 30일 기준 변경 제한
    if (nicknameLastChangedAt == null) {
      return true;
    }

    final DateTime now = DateTime.now();
    final DateTime nextChangeDate = nicknameLastChangedAt!.add(const Duration(days: 30));
    return now.isAfter(nextChangeDate) || now.isAtSameMomentAs(nextChangeDate);
  }

  String? get governmentEmail => userProfile?.governmentEmail;

  /// 라운지 읽기 권한: 로그인한 모든 사용자
  bool get hasLoungeReadAccess => isLoggedIn;

  /// 라운지 쓰기 권한: 공직자 메일 인증 OR 직렬 인증 완료 사용자
  /// 직렬 인증을 완료한 경우 자동으로 메일 인증 권한 포함 (OR 로직)
  bool get hasLoungeWriteAccess =>
      isGovernmentEmailVerified || isCareerTrackVerified;

  /// @deprecated Use hasLoungeReadAccess or hasLoungeWriteAccess instead
  @Deprecated('Use hasLoungeReadAccess or hasLoungeWriteAccess')
  bool get hasLoungeAccess => hasLoungeWriteAccess;

  bool get hasSerialTabAccess => isGovernmentEmailVerified;
}

/// AuthState에 대한 기능 접근 레벨 확장
///
/// FeatureAccessLevel을 사용하여 선언적으로 접근 제어를 구현
extension AuthStateFeatureAccess on AuthState {
  /// 현재 사용자의 접근 레벨 반환
  ///
  /// - Level 0 (guest): 비회원
  /// - Level 1 (member): 회원 (로그인만)
  /// - Level 2 (emailVerified): 공직자 메일 인증
  /// - Level 3 (careerVerified): 직렬 인증
  FeatureAccessLevel get currentAccessLevel {
    // 직렬 인증 완료 (최고 레벨)
    if (isCareerTrackVerified) {
      return FeatureAccessLevel.careerVerified;
    }

    // 공직자 메일 인증 완료
    if (isGovernmentEmailVerified) {
      return FeatureAccessLevel.emailVerified;
    }

    // 로그인만 완료
    if (isLoggedIn) {
      return FeatureAccessLevel.member;
    }

    // 비회원
    return FeatureAccessLevel.guest;
  }

  /// 특정 기능에 접근 가능한지 확인
  ///
  /// 사용 예시:
  /// ```dart
  /// if (authState.canAccess(FeatureAccessLevel.emailVerified)) {
  ///   // 공직자 메일 인증 완료 사용자만 접근 가능
  /// }
  /// ```
  bool canAccess(FeatureAccessLevel requiredLevel) {
    return currentAccessLevel >= requiredLevel;
  }

  /// 다음 레벨 정보 반환
  ///
  /// 사용자가 다음 단계로 올라가기 위한 레벨 정보
  FeatureAccessLevel? get nextAccessLevel {
    return currentAccessLevel.nextLevel;
  }

  /// 다음 레벨로 가기 위한 액션 설명
  String get nextLevelActionDescription {
    return currentAccessLevel.nextLevelActionDescription;
  }

  /// 다음 레벨 인증 페이지 경로
  String? get verificationRoute {
    return currentAccessLevel.verificationRoute;
  }
}
