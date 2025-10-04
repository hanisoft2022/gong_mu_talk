part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isLoggedIn = false,
    this.isProcessing = false,
    this.isAuthenticating = false,
    this.isGovernmentEmailVerificationInProgress = false,
    this.isEmailVerified = false,
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
    this.points = 0,
    this.level = 1,
    this.badges = const <String>[],
    this.photoUrl,
    this.nicknameChangeCount = 0,
    this.nicknameLastChangedAt,
    this.nicknameResetAt,
    this.extraNicknameTickets = 0,
    this.followerCount = 0,
    this.followingCount = 0,
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
  final int points;
  final int level;
  final List<String> badges;
  final String? photoUrl;
  final int nicknameChangeCount;
  final DateTime? nicknameLastChangedAt;
  final DateTime? nicknameResetAt;
  final int extraNicknameTickets;
  final int followerCount;
  final int followingCount;
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
    int? points,
    int? level,
    List<String>? badges,
    String? photoUrl,
    int? nicknameChangeCount,
    DateTime? nicknameLastChangedAt,
    DateTime? nicknameResetAt,
    int? extraNicknameTickets,
    int? followerCount,
    int? followingCount,
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
      points: points ?? this.points,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      photoUrl: photoUrl ?? this.photoUrl,
      nicknameChangeCount: nicknameChangeCount ?? this.nicknameChangeCount,
      nicknameLastChangedAt:
          nicknameLastChangedAt ?? this.nicknameLastChangedAt,
      nicknameResetAt: nicknameResetAt ?? this.nicknameResetAt,
      extraNicknameTickets: extraNicknameTickets ?? this.extraNicknameTickets,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
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
    points,
    level,
    badges,
    photoUrl,
    nicknameChangeCount,
    nicknameLastChangedAt,
    nicknameResetAt,
    extraNicknameTickets,
    followerCount,
    followingCount,
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
    return normalized.endsWith('@korea.kr') || normalized.endsWith('.go.kr') || normalized.endsWith('@naver.com');
  }

  bool get isGovernmentEmailVerified => userProfile?.isGovernmentEmailVerified ?? false;


  bool get hasNicknameTickets => extraNicknameTickets > 0;

  bool get canChangeNickname {
    final DateTime now = DateTime.now();
    final DateTime? resetAnchor = nicknameResetAt;
    if (resetAnchor == null ||
        resetAnchor.year != now.year ||
        resetAnchor.month != now.month) {
      return true;
    }
    return nicknameChangeCount < 1;
  }

  String? get governmentEmail => userProfile?.governmentEmail;

  /// 라운지 읽기 권한: 로그인한 모든 사용자
  bool get hasLoungeReadAccess => isLoggedIn;

  /// 라운지 쓰기 권한: 공직자 메일 인증 완료 사용자
  bool get hasLoungeWriteAccess => isGovernmentEmailVerified;

  /// @deprecated Use hasLoungeReadAccess or hasLoungeWriteAccess instead
  @Deprecated('Use hasLoungeReadAccess or hasLoungeWriteAccess')
  bool get hasLoungeAccess => hasLoungeWriteAccess;

  bool get hasSerialTabAccess => isGovernmentEmailVerified;
}
