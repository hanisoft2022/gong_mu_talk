import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/firebase_auth_repository.dart';
import '../../data/login_session_store.dart';
import '../../../payments/data/bootpay_payment_service.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../notifications/data/notification_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required BootpayPaymentService paymentService,
    required FirebaseAuthRepository authRepository,
    required LoginSessionStore sessionStore,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _paymentService = paymentService,
       _authRepository = authRepository,
       _sessionStore = sessionStore,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository,
       super(const AuthState()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onAuthUserChanged,
    );
  }

  final BootpayPaymentService _paymentService;
  final FirebaseAuthRepository _authRepository;
  final LoginSessionStore _sessionStore;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  late final StreamSubscription<AuthUser?> _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  static const Duration _sessionMaxAge = Duration(days: 30);
  String? _pendingForcedLogoutMessage;

  Future<void> signIn({required String email, required String password}) async {
    return _runAuthOperation(
      () => _authRepository.signIn(
        email: email.trim(),
        password: password.trim(),
      ),
      fallbackMessage: '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    return _runAuthOperation(
      () => _authRepository.signUp(
        email: email.trim(),
        password: password.trim(),
      ),
      fallbackMessage: '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.',
    );
  }

  Future<void> signInWithGoogle() async {
    return _runAuthOperation(
      _authRepository.signInWithGoogle,
      fallbackMessage: 'Google 계정으로 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
    );
  }

  Future<void> signInWithKakao() async {
    return _runAuthOperation(
      _authRepository.signInWithKakao,
      fallbackMessage: '카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
    );
  }

  Future<void> logOut() async {
    try {
      await _authRepository.signOut();
    } on AuthException catch (error) {
      emit(state.copyWith(authError: error.message));
    } catch (_) {
      emit(state.copyWith(authError: '로그아웃에 실패했습니다. 잠시 후 다시 시도해주세요.'));
    }
  }

  Future<void> purchasePensionAccess(BuildContext context) async {
    if (!state.isLoggedIn) {
      emit(state.copyWith(lastMessage: '먼저 로그인 해주세요.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    final PaymentResult result = await _paymentService
        .requestPensionSubscription(
          context: context,
          price: 4990,
          orderId: 'pension-pass-${DateTime.now().millisecondsSinceEpoch}',
        );

    emit(
      state.copyWith(
        isProcessing: false,
        hasPensionAccess: result.isSuccess ? true : state.hasPensionAccess,
        lastMessage: result.message,
      ),
    );
  }

  Future<void> requestGovernmentEmailVerification({
    required String email,
  }) async {
    final String trimmedEmail = email.trim();
    emit(
      state.copyWith(
        isGovernmentEmailVerificationInProgress: true,
        authError: null,
        lastMessage: null,
      ),
    );

    try {
      await _authRepository.requestGovernmentEmailVerification(trimmedEmail);
      emit(
        state.copyWith(
          isGovernmentEmailVerificationInProgress: false,
          isEmailVerified: false,
          lastMessage: '$trimmedEmail 로 인증 메일을 전송했습니다. 메일함을 확인해주세요.',
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isGovernmentEmailVerificationInProgress: false,
          isEmailVerified: false,
          lastMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isGovernmentEmailVerificationInProgress: false,
          isEmailVerified: false,
          lastMessage: '공직자 메일 인증 요청에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> refreshAuthStatus() async {
    await _authRepository.reloadCurrentUser();
    final AuthUser? user = _authRepository.currentAuthUser;
    _onAuthUserChanged(user);
  }

  Future<void> updateCareerTrack(CareerTrack track) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 직렬을 설정할 수 있습니다.'));
      return;
    }

    try {
      final String serial = track == CareerTrack.none ? 'unknown' : track.name;
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, careerTrack: track, serial: serial);

      _applyProfile(profile);

      final String message = track == CareerTrack.none
          ? '직렬 설정이 초기화되었습니다.'
          : '직렬이 ${track.displayName}로 설정되었습니다.';
      emit(state.copyWith(lastMessage: message));
    } catch (_) {
      emit(state.copyWith(lastMessage: '직렬 설정에 실패했습니다. 잠시 후 다시 시도해주세요.'));
    }
  }

  Future<void> addSupporterBadge() async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 후원 배지를 획득할 수 있습니다.'));
      return;
    }

    final int nextLevel = state.supporterLevel + 1;
    try {
      await _userProfileRepository.assignBadge(
        uid: uid,
        badgeId: 'supporter_$nextLevel',
        label: '후원자 레벨 $nextLevel',
        description: '공무톡 후원으로 획득한 배지',
      );
      await _userProfileRepository.incrementPoints(
        uid: uid,
        delta: 50,
        levelDelta: 1,
      );
      await _userProfileRepository.addNicknameTickets(uid: uid, count: 1);
      emit(
        state.copyWith(lastMessage: '후원해주셔서 감사합니다! 레벨 $nextLevel 배지를 획득했습니다.'),
      );
    } catch (_) {
      emit(state.copyWith(lastMessage: '후원 처리 중 오류가 발생했습니다. 다시 시도해주세요.'));
    }
  }

  void enableSupporterMode() {
    if (state.supporterLevel > 0) {
      emit(state.copyWith(lastMessage: '이미 후원 모드가 활성화되어 있습니다.'));
      return;
    }

    emit(
      state.copyWith(
        supporterLevel: 1,
        premiumTier: PremiumTier.supporter,
        lastMessage: '후원 모드가 활성화되었어요! 고맙습니다.',
      ),
    );
  }

  void disableSupporterMode() {
    if (state.supporterLevel == 0 && state.premiumTier == PremiumTier.none) {
      emit(state.copyWith(lastMessage: '이미 일반 모드입니다.'));
      return;
    }

    emit(
      state.copyWith(
        supporterLevel: 0,
        premiumTier: PremiumTier.none,
        lastMessage: '후원을 취소했습니다. 언제든 다시 돌아오세요!',
      ),
    );
  }

  Future<void> updateNickname(String newNickname) async {
    final String trimmed = newNickname.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(lastMessage: '닉네임을 입력해주세요.'));
      return;
    }

    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 닉네임을 변경할 수 있습니다.'));
      return;
    }

    if (!state.canChangeNickname) {
      emit(state.copyWith(lastMessage: '닉네임 변경권이 부족합니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));

    try {
      final UserProfile profile = await _userProfileRepository.updateNickname(
        uid: uid,
        newNickname: trimmed,
      );
      _applyProfile(profile);
      emit(state.copyWith(isProcessing: false, lastMessage: '닉네임이 변경되었습니다.'));
    } on StateError catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } on ArgumentError catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '닉네임 변경 중 오류가 발생했습니다. 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> purchaseNicknameTicket() async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 닉네임 변경권을 구매할 수 있습니다.'));
      return;
    }

    try {
      await _userProfileRepository.addNicknameTickets(uid: uid, count: 1);
      emit(state.copyWith(lastMessage: '닉네임 변경권이 추가되었습니다.'));
    } catch (_) {
      emit(state.copyWith(lastMessage: '닉네임 변경권 추가 중 오류가 발생했습니다.'));
    }
  }

  Future<void> toggleExcludedTrack(CareerTrack track) async {
    final Set<CareerTrack> updated = Set<CareerTrack>.from(
      state.excludedTracks,
    );
    if (!updated.remove(track)) {
      updated.add(track);
    }

    emit(
      state.copyWith(
        excludedTracks: updated,
        excludedSerials: updated.map((CareerTrack track) => track.name).toSet(),
      ),
    );

    final String? uid = state.userId;
    if (uid == null) {
      emit(
        state.copyWith(
          excludedTracks: updated,
          lastMessage: '로그인 후 제외 직렬을 설정할 수 있습니다.',
        ),
      );
      return;
    }

    try {
      await _userProfileRepository.updateExclusionSettings(
        uid: uid,
        excludedSerials: updated.map((CareerTrack track) => track.name).toSet(),
      );
      emit(
        state.copyWith(
          excludedTracks: updated,
          excludedSerials: updated
              .map((CareerTrack track) => track.name)
              .toSet(),
          lastMessage: '매칭 제외 직렬 설정이 업데이트되었습니다.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          excludedTracks: updated,
          excludedSerials: updated
              .map((CareerTrack track) => track.name)
              .toSet(),
          lastMessage: '매칭 제외 직렬 설정에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  void _onAuthUserChanged(AuthUser? user) {
    final bool wasLoggedIn = state.isLoggedIn;

    if (user == null) {
      unawaited(_sessionStore.clearLoginTimestamp());
      _profileSubscription?.cancel();
      unawaited(_notificationRepository.stopListening());

      String? message = state.lastMessage;
      if (_pendingForcedLogoutMessage != null) {
        message = _pendingForcedLogoutMessage;
        _pendingForcedLogoutMessage = null;
      } else if (wasLoggedIn) {
        message = '로그아웃 되었습니다.';
      }

      emit(
        state.copyWith(
          isLoggedIn: false,
          userId: null,
          email: null,
          primaryEmail: null,
          hasPensionAccess: false,
          isAuthenticating: false,
          isGovernmentEmailVerificationInProgress: false,
          isEmailVerified: false,
          authError: null,
          userProfile: null,
          nickname: '공무원',
          careerTrack: CareerTrack.none,
          serial: 'unknown',
          department: 'unknown',
          region: 'unknown',
          jobTitle: '직무 미입력',
          yearsOfService: 0,
          supporterLevel: 0,
          points: 0,
          level: 1,
          badges: const <String>[],
          premiumTier: PremiumTier.none,
          photoUrl: null,
          nicknameChangeCount: 0,
          nicknameLastChangedAt: null,
          nicknameResetAt: null,
          extraNicknameTickets: 0,
          excludedTracks: const <CareerTrack>{},
          excludedSerials: const <String>{},
          excludedDepartments: const <String>{},
          excludedRegions: const <String>{},
          lastMessage: message,
        ),
      );
      return;
    }

    if (_sessionStore.isSessionExpired(_sessionMaxAge)) {
      _pendingForcedLogoutMessage = '보안을 위해 다시 로그인해주세요.';
      unawaited(_forceSignOut());
      return;
    }

    unawaited(_sessionStore.saveLoginTimestamp(DateTime.now()));

    final String? previousEmail = state.email;
    final String? newEmail = user.email;
    if (newEmail != null && newEmail.isNotEmpty) {
      if (previousEmail != null &&
          previousEmail.isNotEmpty &&
          previousEmail != newEmail) {
        unawaited(
          _authRepository.handlePrimaryEmailUpdated(
            userId: user.uid,
            previousEmail: previousEmail,
            newEmail: newEmail,
          ),
        );
      } else {
        unawaited(
          _authRepository.ensureGovernmentEmailRecord(
            userId: user.uid,
            email: newEmail,
            isEmailVerified: user.isEmailVerified,
          ),
        );
      }
    }

    String? message = state.lastMessage;
    if (!wasLoggedIn) {
      message = '로그인 되었습니다.';
    }

    emit(
      state.copyWith(
        isLoggedIn: true,
        userId: user.uid,
        email: user.email,
        primaryEmail: user.email,
        hasPensionAccess: state.hasPensionAccess,
        isAuthenticating: false,
        isGovernmentEmailVerificationInProgress: false,
        isEmailVerified: user.isEmailVerified,
        authError: null,
        lastMessage: message,
      ),
    );

    if (newEmail != null && _isGovernmentEmail(newEmail)) {
      unawaited(_refreshPrimaryEmail(user.uid, newEmail));
    }

    unawaited(_userProfileRepository.recordLogin(user.uid));
    _subscribeToProfile(uid: user.uid, fallbackEmail: newEmail);
    unawaited(_notificationRepository.startListening(user.uid));
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _profileSubscription?.cancel();
    await _notificationRepository.stopListening();
    await super.close();
  }

  Future<void> _runAuthOperation(
    Future<void> Function() operation, {
    required String fallbackMessage,
  }) async {
    emit(
      state.copyWith(
        isAuthenticating: true,
        isGovernmentEmailVerificationInProgress: false,
        authError: null,
        lastMessage: null,
      ),
    );

    try {
      await operation();
    } on AuthException catch (error) {
      emit(state.copyWith(isAuthenticating: false, authError: error.message));
    } catch (_) {
      emit(state.copyWith(isAuthenticating: false, authError: fallbackMessage));
    }
  }

  Future<void> _forceSignOut() async {
    try {
      await _authRepository.signOut();
    } on AuthException catch (error) {
      emit(state.copyWith(authError: error.message));
    } catch (_) {
      emit(state.copyWith(authError: '보안 로그아웃 처리 중 오류가 발생했습니다. 다시 시도해주세요.'));
    }
  }

  void clearLastMessage() {
    if (state.lastMessage == null) {
      return;
    }
    emit(state.copyWith(lastMessage: null));
  }

  bool _isGovernmentEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    return normalized.endsWith('@korea.kr') || normalized.endsWith('.go.kr');
  }

  Future<void> _refreshPrimaryEmail(
    String userId,
    String governmentEmail,
  ) async {
    try {
      final String? legacyEmail = await _authRepository
          .findLegacyEmailForGovernmentEmail(
            userId: userId,
            governmentEmail: governmentEmail,
          );

      if (legacyEmail == null || legacyEmail.isEmpty) {
        return;
      }

      if (isClosed) {
        return;
      }

      if (state.primaryEmail == legacyEmail) {
        return;
      }

      emit(state.copyWith(primaryEmail: legacyEmail));
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to resolve primary email for $governmentEmail: $error\n$stackTrace',
      );
    }
  }

  void _subscribeToProfile({required String uid, String? fallbackEmail}) {
    _profileSubscription?.cancel();
    final String fallbackNickname = _deriveNickname(fallbackEmail);

    _profileSubscription = _userProfileRepository.watchProfile(uid).listen((
      UserProfile? profile,
    ) {
      if (profile == null) {
        return;
      }
      _applyProfile(profile);
    });

    unawaited(
      _userProfileRepository
          .ensureUserProfile(
            uid: uid,
            nickname: fallbackNickname,
            serial: state.serial,
            department: state.department,
            region: state.region,
            jobTitle: state.jobTitle,
            yearsOfService: state.yearsOfService,
          )
          .then(_applyProfile),
    );
  }

  void _applyProfile(UserProfile profile) {
    if (isClosed) {
      return;
    }

    final Set<CareerTrack> excludedTracks = profile.excludedSerials
        .map(_careerTrackFromSerial)
        .where((CareerTrack track) => track != CareerTrack.none)
        .toSet();

    emit(
      state.copyWith(
        userProfile: profile,
        nickname: profile.nickname,
        serial: profile.serial,
        department: profile.department,
        region: profile.region,
        jobTitle: profile.jobTitle,
        yearsOfService: profile.yearsOfService,
        supporterLevel: profile.supporterLevel,
        points: profile.points,
        level: profile.level,
        badges: profile.badges,
        premiumTier: profile.premiumTier,
        careerTrack: profile.careerTrack,
        photoUrl: profile.photoUrl,
        nicknameChangeCount: profile.nicknameChangeCount,
        nicknameLastChangedAt: profile.nicknameLastChangedAt,
        nicknameResetAt: profile.nicknameResetAt,
        extraNicknameTickets: profile.extraNicknameTickets,
        excludedTracks: excludedTracks,
        excludedSerials: profile.excludedSerials,
        excludedDepartments: profile.excludedDepartments,
        excludedRegions: profile.excludedRegions,
      ),
    );
  }

  String _deriveNickname(String? email) {
    if (email == null || email.isEmpty) {
      return '공무원';
    }
    final String localPart = email.split('@').first;
    if (localPart.isEmpty) {
      return '공무원';
    }
    return localPart.length > 12 ? localPart.substring(0, 12) : localPart;
  }

  CareerTrack _careerTrackFromSerial(String serial) {
    final String normalized = serial.trim().toLowerCase();
    for (final CareerTrack track in CareerTrack.values) {
      if (track == CareerTrack.none) {
        continue;
      }
      if (normalized.contains(track.name.toLowerCase())) {
        return track;
      }
    }
    return CareerTrack.none;
  }
}
