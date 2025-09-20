import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _googleServerClientIdOverride = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);

const String _googleIosClientIdOverride = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '',
);

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthUser {
  const AuthUser({required this.uid, this.email, required this.isEmailVerified});

  final String uid;
  final String? email;
  final bool isEmailVerified;
}

class FirebaseAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForSignIn(error));
    } catch (_) {
      throw const AuthException('로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
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
        final Future<void>? initialization = _googleSignInInitialization;
        if (initialization != null) {
          await initialization;
          await _googleSignIn.signOut();
        }
      }
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForSignOut(error));
    } catch (_) {
      throw const AuthException('로그아웃 처리 중 오류가 발생했습니다.');
    }
  }

  void _ensureGoogleMobileConfigIsReady() {
    if (kIsWeb) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final String? clientId = _resolveGoogleIosClientId();
      if (clientId == null || clientId.isEmpty) {
        throw const AuthException(
          'iOS용 Google OAuth 클라이언트 ID가 설정되어 있지 않습니다. Firebase 콘솔에서 iOS 번들 ID와 연결된 OAuth 클라이언트 ID를 생성하고 GoogleService-Info.plist를 업데이트해주세요.',
        );
      }
    }
  }

  String? _resolveGoogleServerClientId() {
    final String override = _googleServerClientIdOverride.trim();
    if (override.isNotEmpty) {
      return override;
    }

    final String? fromOptions = _firebaseAuth.app.options.androidClientId;
    if (fromOptions != null && fromOptions.trim().isNotEmpty) {
      return fromOptions.trim();
    }

    return null;
  }

  String? _resolveGoogleIosClientId() {
    final String override = _googleIosClientIdOverride.trim();
    if (override.isNotEmpty) {
      return override;
    }

    final String? clientId = _firebaseAuth.app.options.iosClientId;
    if (clientId != null && clientId.trim().isNotEmpty) {
      return clientId.trim();
    }

    return null;
  }

  Future<void> _signInWithOidcProvider(String providerId, {required String providerName}) async {
    try {
      _ensureAuthDomainConfigured(providerName);

      final OAuthProvider provider = OAuthProvider(providerId);
      provider.setCustomParameters(<String, String>{'prompt': 'consent'});

      if (kIsWeb) {
        await _firebaseAuth.signInWithPopup(provider);
        return;
      }

      await _firebaseAuth.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForGenericOidc(error));
    } on UnimplementedError catch (_) {
      throw AuthException(
        '$providerName 로그인은 현재 사용 중인 플랫폼에서 바로 사용할 수 없습니다.\nFirebase Authentication에서 $providerName OIDC 제공자를 설정했다면, FlutterFire의 OIDC 네이티브 지원이 포함된 최신 버전으로 업그레이드하거나, Kakao/Naver SDK와 Cloud Functions로 커스텀 토큰을 발급하는 방식으로 전환해야 합니다.',
      );
    } on UnsupportedError catch (_) {
      throw AuthException(
        '$providerName 로그인을 진행하려면 Firebase Authentication 설정에서 Authorized domain을 등록하고, FlutterFire CLI를 다시 실행해 authDomain 정보가 포함된 firebase_options.dart 파일을 생성해야 합니다.',
      );
    } catch (_) {
      throw AuthException('$providerName 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  void _ensureAuthDomainConfigured(String providerName) {
    if (kIsWeb) {
      return;
    }

    final String? authDomain = _firebaseAuth.app.options.authDomain;
    if (authDomain == null || authDomain.trim().isEmpty) {
      throw AuthException(
        '$providerName 로그인을 사용하려면 Firebase Authentication → 설정에서 호스팅 도메인을 확인하고, `firebase login` 후 FlutterFire CLI로 firebase_options.dart를 다시 생성하여 authDomain 값이 포함되도록 해야 합니다.',
      );
    }
  }

  Future<void> signInWithKakao() async {
    await _signInWithOidcProvider('oidc.kakao', providerName: '카카오');
  }

  Future<void> signInWithNaver() async {
    await _signInWithOidcProvider('oidc.naver', providerName: '네이버');
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

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters(<String, String>{'prompt': 'select_account'});
        await _firebaseAuth.signInWithPopup(googleProvider);
        return;
      }

      _ensureGoogleMobileConfigIsReady();

      final GoogleSignIn googleSignIn = await _configuredGoogleSignIn();

      final GoogleSignInAccount googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (error) {
        throw AuthException(_messageForGoogleSignInException(error));
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken?.trim();
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google 로그인에 필요한 ID 토큰이 발급되지 않았습니다.\nFirebase 프로젝트에서 Web 클라이언트 ID를 활성화하고 google-services.json / GoogleService-Info.plist를 다시 내려받아 프로젝트에 반영해주세요.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(idToken: idToken);

      await _firebaseAuth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw AuthException(_messageForGoogleSignInException(error));
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForGoogle(error));
    } catch (_) {
      throw const AuthException('Google 계정으로 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<GoogleSignIn> _configuredGoogleSignIn() async {
    final String? serverClientId = _normalizeClientId(_resolveGoogleServerClientId());

    String? clientId;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      clientId = _normalizeClientId(_resolveGoogleIosClientId());
      if (clientId == null || clientId.isEmpty) {
        throw const AuthException(
          'Google 로그인 구성이 완료되지 않았습니다. Firebase 콘솔에서 iOS용 OAuth 클라이언트 ID를 추가하고 최신 GoogleService-Info.plist 파일을 프로젝트에 반영해주세요.',
        );
      }
    }

    await _initializeGoogleSignInIfNeeded(clientId: clientId, serverClientId: serverClientId);

    return _googleSignIn;
  }

  Future<void> _initializeGoogleSignInIfNeeded({String? clientId, String? serverClientId}) async {
    final Future<void>? existingInitialization = _googleSignInInitialization;
    if (existingInitialization != null) {
      await existingInitialization;
      return;
    }

    final Future<void> initFuture = _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    _googleSignInInitialization = initFuture.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _googleSignInInitialization = null;
        throw error;
      },
    );

    await _googleSignInInitialization;
  }

  String? _normalizeClientId(String? value) {
    if (value == null) {
      return null;
    }

    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String _messageForGoogleSignInException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google 로그인 절차가 취소되었습니다.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google 로그인 과정이 중단되었습니다. 잠시 후 다시 시도해주세요.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google 로그인 UI를 표시할 수 없습니다. 잠시 후 다시 시도해주세요.';
      case GoogleSignInExceptionCode.userMismatch:
        return '다른 Google 계정이 이미 로그인되어 있습니다. 로그아웃 후 다시 시도해주세요.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        final String? description = error.description;
        final String detail = (description == null || description.isEmpty)
            ? ''
            : '\n상세: $description';
        return 'Google 로그인 구성이 완료되지 않았습니다. Firebase 콘솔의 OAuth 클라이언트 ID 설정과 FlutterFire CLI로 생성된 firebase_options.dart 파일을 다시 확인해주세요.$detail';
      default:
        final String? description = error.description;
        if (description != null && description.isNotEmpty) {
          return 'Google 로그인 중 오류가 발생했습니다: $description';
        }
        return 'Google 로그인 처리 중 오류(${error.code.name})가 발생했습니다.';
    }
  }
}
