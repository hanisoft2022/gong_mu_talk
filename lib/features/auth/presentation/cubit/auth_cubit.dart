import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/firebase_auth_repository.dart';
import '../../../payments/data/bootpay_payment_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required BootpayPaymentService paymentService,
    required FirebaseAuthRepository authRepository,
  }) : _paymentService = paymentService,
       _authRepository = authRepository,
       super(const AuthState()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onAuthUserChanged,
    );
  }

  final BootpayPaymentService _paymentService;
  final FirebaseAuthRepository _authRepository;
  late final StreamSubscription<AuthUser?> _authSubscription;

  Future<void> signIn({required String email, required String password}) async {
    emit(
      state.copyWith(
        isAuthenticating: true,
        authError: null,
        lastMessage: null,
      ),
    );

    try {
      await _authRepository.signIn(
        email: email.trim(),
        password: password.trim(),
      );
    } on AuthException catch (error) {
      emit(state.copyWith(isAuthenticating: false, authError: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isAuthenticating: false,
          authError: '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(
      state.copyWith(
        isAuthenticating: true,
        authError: null,
        lastMessage: null,
      ),
    );

    try {
      await _authRepository.signUp(
        email: email.trim(),
        password: password.trim(),
      );
    } on AuthException catch (error) {
      emit(state.copyWith(isAuthenticating: false, authError: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isAuthenticating: false,
          authError: '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
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

  void _onAuthUserChanged(AuthUser? user) {
    final bool wasLoggedIn = state.isLoggedIn;
    final bool isLoggedIn = user != null;

    String? message;
    if (wasLoggedIn != isLoggedIn) {
      message = isLoggedIn ? '로그인 되었습니다.' : '로그아웃 되었습니다.';
    }

    emit(
      state.copyWith(
        isLoggedIn: isLoggedIn,
        email: user?.email,
        hasPensionAccess: isLoggedIn ? state.hasPensionAccess : false,
        isAuthenticating: false,
        authError: null,
        lastMessage: message ?? state.lastMessage,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await super.close();
  }
}
