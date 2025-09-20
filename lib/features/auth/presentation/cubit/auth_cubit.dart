import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/firebase_auth_repository.dart';
import '../../data/login_session_store.dart';
import '../../../payments/data/bootpay_payment_service.dart';
import '../../../profile/domain/career_track.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required BootpayPaymentService paymentService,
    required FirebaseAuthRepository authRepository,
    required LoginSessionStore sessionStore,
  }) : _paymentService = paymentService,
       _authRepository = authRepository,
       _sessionStore = sessionStore,
       super(const AuthState()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onAuthUserChanged,
    );
  }

  final BootpayPaymentService _paymentService;
  final FirebaseAuthRepository _authRepository;
  final LoginSessionStore _sessionStore;
  late final StreamSubscription<AuthUser?> _authSubscription;
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

  Future<void> signInWithNaver() async {
    return _runAuthOperation(
      _authRepository.signInWithNaver,
      fallbackMessage: '네이버 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
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

  void updateCareerTrack(CareerTrack track) {
    emit(
      state.copyWith(
        careerTrack: track,
        lastMessage: '직렬이 ${track.displayName}로 설정되었습니다.',
      ),
    );
  }

  void addSupporterBadge() {
    final int nextLevel = state.supporterLevel + 1;
    emit(
      state.copyWith(
        supporterLevel: nextLevel,
        extraNicknameTickets: state.extraNicknameTickets + 1,
        lastMessage: '후원해주셔서 감사합니다! 레벨 $nextLevel 배지를 획득했습니다.',
      ),
    );
  }

  void updateNickname(String newNickname) {
    final DateTime now = DateTime.now();
    DateTime resetAnchor = state.nicknameResetAt ?? now;
    int changeCount = state.nicknameChangeCount;
    int tickets = state.extraNicknameTickets;

    if (resetAnchor.year != now.year || resetAnchor.month != now.month) {
      resetAnchor = DateTime(now.year, now.month);
      changeCount = 0;
    }

    if (newNickname.trim().isEmpty) {
      emit(state.copyWith(lastMessage: '닉네임을 입력해주세요.'));
      return;
    }

    if (changeCount >= 2 && tickets <= 0) {
      emit(state.copyWith(lastMessage: '이번 달 닉네임 변경 가능 횟수를 모두 사용했습니다.'));
      return;
    }

    if (changeCount >= 2 && tickets > 0) {
      tickets -= 1;
    } else {
      changeCount += 1;
    }

    emit(
      state.copyWith(
        nickname: newNickname.trim(),
        nicknameChangeCount: changeCount,
        nicknameLastChangedAt: now,
        nicknameResetAt: resetAnchor,
        extraNicknameTickets: tickets,
        lastMessage: '닉네임이 변경되었습니다.',
      ),
    );
  }

  void purchaseNicknameTicket() {
    emit(
      state.copyWith(
        extraNicknameTickets: state.extraNicknameTickets + 1,
        lastMessage: '닉네임 변경권이 추가되었습니다.',
      ),
    );
  }

  void toggleExcludedTrack(CareerTrack track) {
    final Set<CareerTrack> updated = Set<CareerTrack>.from(
      state.excludedTracks,
    );
    if (!updated.remove(track)) {
      updated.add(track);
    }

    emit(
      state.copyWith(
        excludedTracks: updated,
        lastMessage: '매칭 제외 직렬 설정이 업데이트되었습니다.',
      ),
    );
  }

  void _onAuthUserChanged(AuthUser? user) {
    final bool wasLoggedIn = state.isLoggedIn;
    final bool isLoggedIn = user != null;

    if (isLoggedIn) {
      if (_sessionStore.isSessionExpired(_sessionMaxAge)) {
        _pendingForcedLogoutMessage = '보안을 위해 다시 로그인해주세요.';
        unawaited(_forceSignOut());
        return;
      }
      unawaited(_sessionStore.saveLoginTimestamp(DateTime.now()));
    } else {
      unawaited(_sessionStore.clearLoginTimestamp());
    }

    String? message = state.lastMessage;
    if (_pendingForcedLogoutMessage != null && !isLoggedIn) {
      message = _pendingForcedLogoutMessage;
      _pendingForcedLogoutMessage = null;
    } else if (wasLoggedIn != isLoggedIn) {
      message = isLoggedIn ? '로그인 되었습니다.' : '로그아웃 되었습니다.';
    }

    emit(
      state.copyWith(
        isLoggedIn: isLoggedIn,
        userId: user?.uid,
        email: user?.email,
        hasPensionAccess: isLoggedIn ? state.hasPensionAccess : false,
        isAuthenticating: false,
        isGovernmentEmailVerificationInProgress: false,
        isEmailVerified: user?.isEmailVerified ?? false,
        authError: null,
        lastMessage: message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
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
}
