import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}

class FirebaseAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForSignIn(error));
    } catch (_) {
      throw const AuthException('로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForSignUp(error));
    } catch (_) {
      throw const AuthException('회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForSignOut(error));
    } catch (_) {
      throw const AuthException('로그아웃 처리 중 오류가 발생했습니다.');
    }
  }

  AuthUser? _mapUser(User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    return AuthUser(uid: firebaseUser.uid, email: firebaseUser.email);
  }

  String _messageForSignIn(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return '이메일 주소 형식을 확인해주세요.';
      case 'user-disabled':
        return '해당 계정은 비활성화되었습니다. 관리자에게 문의하세요.';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  String _messageForSignUp(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return '이메일 주소 형식을 확인해주세요.';
      case 'email-already-in-use':
        return '이미 가입된 이메일입니다. 로그인 해주세요.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'operation-not-allowed':
        return '현재 이메일 가입이 비활성화되어 있습니다. 관리자에게 문의하세요.';
      default:
        return '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  String _messageForSignOut(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인한 뒤 로그아웃을 시도해주세요.';
      default:
        return '로그아웃 처리 중 오류가 발생했습니다.';
    }
  }
}
