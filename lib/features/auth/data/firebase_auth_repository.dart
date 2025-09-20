import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    required this.isEmailVerified,
  });

  final String uid;
  final String? email;
  final bool isEmailVerified;
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
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForSignOut(error));
    } catch (_) {
      throw const AuthException('로그아웃 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters(<String, String>{
          'prompt': 'select_account',
        });
        await _firebaseAuth.signInWithPopup(googleProvider);
        return;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google 로그인 절차가 취소되었습니다.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForGoogle(error));
    } catch (_) {
      throw const AuthException('Google 계정으로 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> signInWithKakao() async {
    try {
      final OAuthProvider provider = OAuthProvider('oidc.kakao');
      await _firebaseAuth.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForGenericOidc(error));
    } catch (_) {
      throw const AuthException('카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> signInWithNaver() async {
    try {
      final OAuthProvider provider = OAuthProvider('oidc.naver');
      await _firebaseAuth.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForGenericOidc(error));
    } catch (_) {
      throw const AuthException('네이버 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> requestGovernmentEmailVerification(String email) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('로그인 후 이용해주세요.');
    }

    final String normalizedEmail = email.trim();
    if (!_isGovernmentEmail(normalizedEmail)) {
      throw const AuthException('공직자 메일(@korea.kr, .go.kr) 주소만 인증할 수 있습니다.');
    }

    try {
      if (normalizedEmail == (user.email ?? '').trim()) {
        if (user.emailVerified) {
          throw const AuthException('이미 공직자 메일로 인증이 완료되었습니다.');
        }
        await user.sendEmailVerification();
        return;
      }

      await user.verifyBeforeUpdateEmail(normalizedEmail);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForGovernmentEmail(error));
    } catch (_) {
      throw const AuthException('인증 메일 전송 중 문제가 발생했습니다.');
    }
  }

  AuthUser? _mapUser(User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      isEmailVerified: firebaseUser.emailVerified,
    );
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
        return '비밀번호는 최소 8자 이상이어야 합니다.';
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

  String _messageForGoogle(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return '이미 다른 로그인 방식과 연결된 계정입니다. 기존 방법으로 로그인 후 계정을 연결해주세요.';
      case 'invalid-credential':
        return 'Google 인증 정보가 올바르지 않습니다. 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '현재 Google 로그인이 비활성화되어 있습니다. 관리자에게 문의하세요.';
      case 'user-disabled':
        return '해당 계정은 비활성화되어 있습니다. 관리자에게 문의하세요.';
      default:
        return 'Google 계정으로 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  String _messageForGovernmentEmail(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인한 뒤 공직자 메일 인증을 시도해주세요.';
      case 'invalid-email':
        return '올바른 공직자 메일 주소를 입력해주세요.';
      case 'email-already-in-use':
        return '이미 다른 계정에서 사용 중인 이메일입니다. 관리자에게 문의해주세요.';
      default:
        return '인증 메일 전송 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  bool _isGovernmentEmail(String email) {
    final String normalized = email.toLowerCase();
    return normalized.endsWith('@korea.kr') || normalized.endsWith('.go.kr');
  }

  Future<void> reloadCurrentUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (_) {
      // no-op
    }
  }

  AuthUser? get currentAuthUser => _mapUser(_firebaseAuth.currentUser);

  String _messageForGenericOidc(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return '네트워크 연결을 확인한 뒤 다시 시도해주세요.';
      case 'account-exists-with-different-credential':
        return '이미 다른 로그인 방식과 연결된 계정입니다. 기존 계정으로 로그인해주세요.';
      case 'user-disabled':
        return '해당 계정은 비활성화되었습니다. 관리자에게 문의하세요.';
      default:
        return '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
  }
}
