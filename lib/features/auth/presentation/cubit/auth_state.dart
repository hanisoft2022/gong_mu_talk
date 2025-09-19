part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    this.isLoggedIn = false,
    this.hasPensionAccess = false,
    this.isProcessing = false,
    this.isAuthenticating = false,
    this.email,
    this.authError,
    this.lastMessage,
  });

  final bool isLoggedIn;
  final bool hasPensionAccess;
  final bool isProcessing;
  final bool isAuthenticating;
  final String? email;
  final String? authError;
  final String? lastMessage;

  static const Object _unset = Object();

  AuthState copyWith({
    bool? isLoggedIn,
    bool? hasPensionAccess,
    bool? isProcessing,
    bool? isAuthenticating,
    Object? email = _unset,
    Object? authError = _unset,
    Object? lastMessage = _unset,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasPensionAccess: hasPensionAccess ?? this.hasPensionAccess,
      isProcessing: isProcessing ?? this.isProcessing,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
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
    email,
    authError,
    lastMessage,
  ];
}
