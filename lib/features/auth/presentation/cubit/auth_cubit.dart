import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../payments/data/bootpay_payment_service.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required BootpayPaymentService paymentService})
      : _paymentService = paymentService,
        super(const AuthState());

  final BootpayPaymentService _paymentService;

  void logIn() {
    emit(state.copyWith(isLoggedIn: true, lastMessage: '로그인 되었습니다.'));
  }

  void logOut() {
    emit(const AuthState(lastMessage: '로그아웃 되었습니다.')); // resets benefits
  }

  Future<void> purchasePensionAccess(BuildContext context) async {
    if (!state.isLoggedIn) {
      emit(state.copyWith(lastMessage: '먼저 로그인 해주세요.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    final PaymentResult result = await _paymentService.requestPensionSubscription(
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
}
