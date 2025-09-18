part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isLoggedIn = false,
    this.hasPensionAccess = false,
    this.isProcessing = false,
    this.lastMessage,
  });

  final bool isLoggedIn;
  final bool hasPensionAccess;
  final bool isProcessing;
  final String? lastMessage;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? hasPensionAccess,
    bool? isProcessing,
    String? lastMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasPensionAccess: hasPensionAccess ?? this.hasPensionAccess,
      isProcessing: isProcessing ?? this.isProcessing,
      lastMessage: lastMessage,
    );
  }

  @override
  List<Object?> get props => [isLoggedIn, hasPensionAccess, isProcessing, lastMessage];
}
