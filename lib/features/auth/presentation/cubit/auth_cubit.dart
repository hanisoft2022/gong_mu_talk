import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  void logIn() {
    emit(state.copyWith(isLoggedIn: true, lastMessage: '로그인 되었습니다.'));
  }

  void logOut() {
    emit(const AuthState(lastMessage: '로그아웃 되었습니다.')); // resets benefits
  }

  Future<void> purchasePensionAccess() async {
    if (!state.isLoggedIn) {
      emit(state.copyWith(lastMessage: '먼저 로그인 해주세요.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(
      state.copyWith(
        isProcessing: false,
        hasPensionAccess: true,
        lastMessage: '연금 계산 서비스 이용권이 활성화되었습니다.',
      ),
    );
  }
}
