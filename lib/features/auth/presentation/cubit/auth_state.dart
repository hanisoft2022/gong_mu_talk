part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isLoggedIn = false,
    this.hasPensionAccess = false,
    this.isProcessing = false,
    this.isAuthenticating = false,
    this.isGovernmentEmailVerificationInProgress = false,
    this.isEmailVerified = false,
    this.userProfile,
    this.careerTrack = CareerTrack.none,
    this.nickname = '공무원',
    this.serial = 'unknown',
    this.department = 'unknown',
    this.region = 'unknown',
    this.jobTitle = '직무 미입력',
    this.yearsOfService = 0,
    this.supporterLevel = 0,
    this.points = 0,
    this.level = 1,
    this.badges = const <String>[],
    this.premiumTier = PremiumTier.none,
    this.photoUrl,
    this.nicknameChangeCount = 0,
    this.nicknameLastChangedAt,
    this.nicknameResetAt,
    this.extraNicknameTickets = 0,
    this.excludedTracks = const <CareerTrack>{},
    this.excludedSerials = const <String>{},
    this.excludedDepartments = const <String>{},
    this.excludedRegions = const <String>{},
    this.userId,
    this.email,
    this.primaryEmail,
    this.authError,
    this.lastMessage,
  });

  final bool isLoggedIn;
  final bool hasPensionAccess;
  final bool isProcessing;
  final bool isAuthenticating;
  final bool isGovernmentEmailVerificationInProgress;
  final bool isEmailVerified;
  final UserProfile? userProfile;
  final CareerTrack careerTrack;
  final String nickname;
  final String serial;
  final String department;
  final String region;
  final String jobTitle;
  final int yearsOfService;
  final int supporterLevel;
  final int points;
  final int level;
  final List<String> badges;
  final PremiumTier premiumTier;
  final String? photoUrl;
  final int nicknameChangeCount;
  final DateTime? nicknameLastChangedAt;
  final DateTime? nicknameResetAt;
  final int extraNicknameTickets;
  final Set<CareerTrack> excludedTracks;
  final Set<String> excludedSerials;
  final Set<String> excludedDepartments;
  final Set<String> excludedRegions;
  final String? userId;
  final String? email;
  final String? primaryEmail;
  final String? authError;
  final String? lastMessage;

  static const Object _unset = Object();

  AuthState copyWith({
    bool? isLoggedIn,
    bool? hasPensionAccess,
    bool? isProcessing,
    bool? isAuthenticating,
    bool? isGovernmentEmailVerificationInProgress,
    bool? isEmailVerified,
    UserProfile? userProfile,
    CareerTrack? careerTrack,
    String? nickname,
    String? serial,
    String? department,
    String? region,
    String? jobTitle,
    int? yearsOfService,
    int? supporterLevel,
    int? points,
    int? level,
    List<String>? badges,
    PremiumTier? premiumTier,
    String? photoUrl,
    int? nicknameChangeCount,
    DateTime? nicknameLastChangedAt,
    DateTime? nicknameResetAt,
    int? extraNicknameTickets,
    Set<CareerTrack>? excludedTracks,
    Set<String>? excludedSerials,
    Set<String>? excludedDepartments,
    Set<String>? excludedRegions,
    Object? userId = _unset,
    Object? email = _unset,
    Object? primaryEmail = _unset,
    Object? authError = _unset,
    Object? lastMessage = _unset,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasPensionAccess: hasPensionAccess ?? this.hasPensionAccess,
      isProcessing: isProcessing ?? this.isProcessing,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isGovernmentEmailVerificationInProgress:
          isGovernmentEmailVerificationInProgress ??
          this.isGovernmentEmailVerificationInProgress,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      userProfile: userProfile ?? this.userProfile,
      careerTrack: careerTrack ?? this.careerTrack,
      nickname: nickname ?? this.nickname,
      serial: serial ?? this.serial,
      department: department ?? this.department,
      region: region ?? this.region,
      jobTitle: jobTitle ?? this.jobTitle,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      supporterLevel: supporterLevel ?? this.supporterLevel,
      points: points ?? this.points,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      premiumTier: premiumTier ?? this.premiumTier,
      photoUrl: photoUrl ?? this.photoUrl,
      nicknameChangeCount: nicknameChangeCount ?? this.nicknameChangeCount,
      nicknameLastChangedAt:
          nicknameLastChangedAt ?? this.nicknameLastChangedAt,
      nicknameResetAt: nicknameResetAt ?? this.nicknameResetAt,
      extraNicknameTickets: extraNicknameTickets ?? this.extraNicknameTickets,
      excludedTracks: excludedTracks ?? this.excludedTracks,
      excludedSerials: excludedSerials ?? this.excludedSerials,
      excludedDepartments: excludedDepartments ?? this.excludedDepartments,
      excludedRegions: excludedRegions ?? this.excludedRegions,
      userId: userId == _unset ? this.userId : userId as String?,
      email: email == _unset ? this.email : email as String?,
      primaryEmail: primaryEmail == _unset ? this.primaryEmail : primaryEmail as String?,
      authError: authError == _unset ? this.authError : authError as String?,
      lastMessage: lastMessage == _unset ? this.lastMessage : lastMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoggedIn,
    hasPensionAccess,
    isProcessing,
    isAuthenticating,
    isGovernmentEmailVerificationInProgress,
    isEmailVerified,
    userProfile,
    careerTrack,
    nickname,
    serial,
    department,
    region,
    jobTitle,
    yearsOfService,
    supporterLevel,
    points,
    level,
    badges,
    premiumTier,
    photoUrl,
    nicknameChangeCount,
    nicknameLastChangedAt,
    nicknameResetAt,
    extraNicknameTickets,
    excludedTracks,
    excludedSerials,
    excludedDepartments,
    excludedRegions,
    userId,
    email,
    primaryEmail,
    authError,
    lastMessage,
  ];

  String? get preferredEmail => primaryEmail ?? email;

  bool get isGovernmentEmail {
    final String? currentEmail = email;
    if (currentEmail == null) {
      return false;
    }
    final String normalized = currentEmail.trim().toLowerCase();
    return normalized.endsWith('@korea.kr') || normalized.endsWith('.go.kr');
  }

  bool get isGovernmentEmailVerified => isGovernmentEmail && isEmailVerified;

  bool get isPremium => premiumTier != PremiumTier.none;

  bool get hasNicknameTickets => extraNicknameTickets > 0;

  bool get canChangeNickname {
    final DateTime now = DateTime.now();
    final DateTime effectiveReset = nicknameResetAt ?? now;
    if (effectiveReset.year != now.year || effectiveReset.month != now.month) {
      return true;
    }
    return nicknameChangeCount < 2 || hasNicknameTickets;
  }
}
