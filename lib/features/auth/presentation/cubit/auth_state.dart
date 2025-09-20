part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isLoggedIn = false,
    this.hasPensionAccess = false,
    this.isProcessing = false,
    this.isAuthenticating = false,
    this.isGovernmentEmailVerificationInProgress = false,
    this.isEmailVerified = false,
    this.careerTrack = CareerTrack.none,
    this.supporterLevel = 0,
    this.nickname = '공무원',
    this.nicknameChangeCount = 0,
    this.nicknameLastChangedAt,
    this.nicknameResetAt,
    this.extraNicknameTickets = 0,
    Set<CareerTrack>? excludedTracks,
    this.userId,
    this.email,
    this.authError,
    this.lastMessage,
  }) : excludedTracks = excludedTracks ?? const <CareerTrack>{};

  final bool isLoggedIn;
  final bool hasPensionAccess;
  final bool isProcessing;
  final bool isAuthenticating;
  final bool isGovernmentEmailVerificationInProgress;
  final bool isEmailVerified;
  final CareerTrack careerTrack;
  final int supporterLevel;
  final String nickname;
  final int nicknameChangeCount;
  final DateTime? nicknameLastChangedAt;
  final DateTime? nicknameResetAt;
  final int extraNicknameTickets;
  final Set<CareerTrack> excludedTracks;
  final String? userId;
  final String? email;
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
    CareerTrack? careerTrack,
    int? supporterLevel,
    String? nickname,
    int? nicknameChangeCount,
    DateTime? nicknameLastChangedAt,
    DateTime? nicknameResetAt,
    int? extraNicknameTickets,
    Set<CareerTrack>? excludedTracks,
    Object? userId = _unset,
    Object? email = _unset,
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
      careerTrack: careerTrack ?? this.careerTrack,
      supporterLevel: supporterLevel ?? this.supporterLevel,
      nickname: nickname ?? this.nickname,
      nicknameChangeCount: nicknameChangeCount ?? this.nicknameChangeCount,
      nicknameLastChangedAt:
          nicknameLastChangedAt ?? this.nicknameLastChangedAt,
      nicknameResetAt: nicknameResetAt ?? this.nicknameResetAt,
      extraNicknameTickets: extraNicknameTickets ?? this.extraNicknameTickets,
      excludedTracks: excludedTracks ?? this.excludedTracks,
      userId: userId == _unset ? this.userId : userId as String?,
      email: email == _unset ? this.email : email as String?,
      authError: authError == _unset ? this.authError : authError as String?,
      lastMessage: lastMessage == _unset
          ? this.lastMessage
          : lastMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    isLoggedIn,
    hasPensionAccess,
    isProcessing,
    isAuthenticating,
    isGovernmentEmailVerificationInProgress,
    isEmailVerified,
    careerTrack,
    supporterLevel,
    nickname,
    nicknameChangeCount,
    nicknameLastChangedAt,
    nicknameResetAt,
    extraNicknameTickets,
    excludedTracks,
    userId,
    email,
    authError,
    lastMessage,
  ];

  bool get isGovernmentEmail {
    final String? currentEmail = email;
    if (currentEmail == null) {
      return false;
    }

    final String normalized = currentEmail.trim().toLowerCase();
    return normalized.endsWith('@korea.kr') || normalized.endsWith('.go.kr');
  }

  bool get isGovernmentEmailVerified => isGovernmentEmail && isEmailVerified;

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
