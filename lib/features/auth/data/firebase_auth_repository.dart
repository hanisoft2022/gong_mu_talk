import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'government_email_repository.dart';

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
  const AuthUser({
    required this.uid,
    this.email,
    required this.isEmailVerified,
    this.isPasswordProvider = true,
  });

  final String uid;
  final String? email;
  final bool isEmailVerified;
  final bool isPasswordProvider; // true if email/password, false if Google/etc
}

class FirebaseAuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GovernmentEmailRepository? governmentEmailRepository,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _governmentEmailRepository =
           governmentEmailRepository ?? GovernmentEmailRepository();

  final FirebaseAuth _firebaseAuth;
  final GovernmentEmailRepository _governmentEmailRepository;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  Future<void> signIn({required String email, required String password}) async {
    final String normalizedEmail = email.trim();

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        final GovernmentEmailAlias? alias = await _governmentEmailRepository
            .findAliasForLegacyEmail(normalizedEmail);
        if (alias != null) {
          try {
            await _firebaseAuth.signInWithEmailAndPassword(
              email: alias.governmentEmail,
              password: password,
            );
            return;
          } on FirebaseAuthException catch (aliasError) {
            throw AuthException(_messageForSignIn(aliasError));
          }
        }
      }

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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User? user = _firebaseAuth.currentUser;
    final String? email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AuthException('로그인 상태를 확인할 수 없습니다. 다시 로그인 후 시도해주세요.');
    }

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForPasswordChange(error));
    } catch (_) {
      throw const AuthException('비밀번호 변경에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> deleteAccount({String? currentPassword}) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('로그인 상태를 확인할 수 없습니다.');
    }

    try {
      if (currentPassword != null && currentPassword.isNotEmpty) {
        final String? email = user.email;
        if (email != null && email.isNotEmpty) {
          final AuthCredential credential = EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);
        }
      }

      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForAccountDeletion(error));
    } catch (_) {
      throw const AuthException('회원 탈퇴 처리 중 문제가 발생했습니다. 다시 시도해주세요.');
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

  Future<String> requestGovernmentEmailVerification(String email) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('로그인 후 이용해주세요.');
    }

    final String normalizedEmail = email.trim().toLowerCase();
    if (!_isGovernmentEmail(normalizedEmail)) {
      throw const AuthException(
        '공직자 메일(@korea.kr, .go.kr) 또는 공직자메일 서비스(@naver.com) 주소만 인증할 수 있습니다.',
      );
    }

    try {
      // 새로운 토큰 기반 인증 방식 사용
      final String token = await _governmentEmailRepository
          .createVerificationToken(
            userId: user.uid,
            governmentEmail: normalizedEmail,
          );

      // @naver.com 도메인의 경우 실제 메일 발송 (Cloud Functions에서 자동 처리)
      // 다른 도메인(*.go.kr)은 실제 메일 서비스 문제로 토큰만 반환
      if (normalizedEmail.endsWith('@naver.com')) {
        debugPrint(
          'Email will be sent automatically via Cloud Functions for $normalizedEmail',
        );
      } else {
        debugPrint(
          'Verification token for $normalizedEmail (email service unavailable): $token',
        );
      }

      return token;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Failed to create verification token for $normalizedEmail: $error\n$stackTrace',
      );
      // Firebase 권한 관련 에러인 경우 더 구체적인 메시지 제공
      if (error.code == 'permission-denied') {
        throw const AuthException('Firebase 권한 설정에 문제가 있습니다. 개발자에게 문의해주세요.');
      } else if (error.code == 'unavailable') {
        throw const AuthException(
          'Firebase 서비스에 일시적으로 접근할 수 없습니다. 잠시 후 다시 시도해주세요.',
        );
      } else {
        throw AuthException('공직자 메일 인증 정보를 저장하지 못했습니다. 오류: ${error.code}');
      }
    } on Exception catch (error) {
      if (error.toString().contains('이미 다른 사용자가 인증한')) {
        throw const AuthException('이미 등록된 공직자 메일입니다. 다른 공직자 메일로 인증해주세요.');
      }
      throw const AuthException('공직자 메일 인증 요청에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } catch (error, stackTrace) {
      debugPrint(
        'Unexpected government email verification error: $error\n$stackTrace',
      );
      throw const AuthException('인증 메일 전송 중 문제가 발생했습니다.');
    }
  }

  /// 공직자 메일 인증 토큰 검증
  Future<bool> verifyGovernmentEmailToken(String token) async {
    try {
      return await _governmentEmailRepository.verifyToken(token);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Failed to verify token $token: $error\n$stackTrace');
      return false;
    } catch (error, stackTrace) {
      debugPrint('Unexpected token verification error: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> handlePrimaryEmailUpdated({
    required String userId,
    required String previousEmail,
    required String newEmail,
  }) async {
    final String trimmedNew = newEmail.trim().toLowerCase();
    if (!_isGovernmentEmail(trimmedNew)) {
      return;
    }

    final String trimmedPrevious = previousEmail.trim();
    final User? currentUser = _firebaseAuth.currentUser;
    final List<String> providerIds =
        currentUser?.providerData
            .map((UserInfo info) => info.providerId)
            .toList(growable: false) ??
        const <String>[];

    await _governmentEmailRepository.markVerified(
      userId: userId,
      governmentEmail: trimmedNew,
      originalEmail: trimmedPrevious,
      providerIds: providerIds,
      displayName: currentUser?.displayName,
      photoUrl: currentUser?.photoURL,
      verifiedEmail: currentUser?.email,
    );

    final bool hasPasswordProvider = providerIds.contains('password');
    if (hasPasswordProvider &&
        trimmedPrevious.isNotEmpty &&
        !_isGovernmentEmail(trimmedPrevious)) {
      await _governmentEmailRepository.upsertAlias(
        legacyEmail: trimmedPrevious,
        governmentEmail: trimmedNew,
        userId: userId,
        displayName: currentUser?.displayName,
        photoUrl: currentUser?.photoURL,
      );
    }
  }

  Future<void> ensureGovernmentEmailRecord({
    required String userId,
    required String email,
    required bool isEmailVerified,
  }) async {
    final String trimmedEmail = email.trim().toLowerCase();
    if (!_isGovernmentEmail(trimmedEmail) || !isEmailVerified) {
      return;
    }

    final GovernmentEmailClaim? existingClaim = await _governmentEmailRepository
        .fetchClaim(trimmedEmail);

    final Set<String> providerIds = <String>{
      ...?existingClaim?.originalProviderIds,
      ...(_firebaseAuth.currentUser?.providerData.map(
            (UserInfo info) => info.providerId,
          ) ??
          const Iterable<String>.empty()),
    };

    final List<String> providerIdList = providerIds.toList(growable: false);

    await _governmentEmailRepository.ensureVerifiedClaim(
      userId: userId,
      governmentEmail: trimmedEmail,
      displayName: _firebaseAuth.currentUser?.displayName,
      photoUrl: _firebaseAuth.currentUser?.photoURL,
      verifiedEmail: _firebaseAuth.currentUser?.email,
      providerIds: providerIdList,
    );

    final GovernmentEmailClaim? refreshedClaim =
        existingClaim ??
        await _governmentEmailRepository.fetchClaim(trimmedEmail);
    final String? legacyEmail = refreshedClaim?.originalEmail;

    if (legacyEmail == null ||
        legacyEmail.isEmpty ||
        _isGovernmentEmail(legacyEmail)) {
      return;
    }

    providerIds.addAll(refreshedClaim?.originalProviderIds ?? const <String>[]);

    if (providerIds.contains('password')) {
      await _governmentEmailRepository.upsertAlias(
        legacyEmail: legacyEmail,
        governmentEmail: trimmedEmail,
        userId: userId,
        displayName: _firebaseAuth.currentUser?.displayName,
        photoUrl: _firebaseAuth.currentUser?.photoURL,
      );
    }
  }

  Future<String?> findLegacyEmailForGovernmentEmail({
    required String userId,
    required String governmentEmail,
  }) {
    return _governmentEmailRepository.findOriginalEmailForGovernmentEmail(
      userId: userId,
      governmentEmail: governmentEmail,
    );
  }

  AuthUser? _mapUser(User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    // Check if user signed in with password (email/password provider)
    // If user has google.com provider, they used Google Sign-In
    final bool hasPasswordProvider = firebaseUser.providerData.any(
      (info) => info.providerId == 'password',
    );

    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      isEmailVerified: firebaseUser.emailVerified,
      isPasswordProvider: hasPasswordProvider,
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

  String _messageForPasswordChange(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
        return '현재 비밀번호가 올바르지 않습니다.';
      case 'weak-password':
        return '새 비밀번호는 최소 8자 이상이어야 합니다.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인한 뒤 비밀번호를 변경해주세요.';
      default:
        return '비밀번호 변경에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  String _messageForAccountDeletion(FirebaseAuthException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인한 뒤 탈퇴를 진행해주세요.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'user-token-expired':
        return '세션이 만료되었습니다. 다시 로그인 후 탈퇴해주세요.';
      default:
        return '회원 탈퇴 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
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

  bool _isGovernmentEmail(String email) {
    final String normalized = email.toLowerCase();
    // 임시로 @naver.com 도메인도 허용
    return normalized.endsWith('@korea.kr') ||
        normalized.endsWith('.go.kr') ||
        normalized.endsWith('@naver.com');
  }

  Future<void> reloadCurrentUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (_) {
      // no-op
    }
  }

  AuthUser? get currentAuthUser => _mapUser(_firebaseAuth.currentUser);

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

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

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
    final String? serverClientId = _normalizeClientId(
      _resolveGoogleServerClientId(),
    );

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

    await _initializeGoogleSignInIfNeeded(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    return _googleSignIn;
  }

  Future<void> _initializeGoogleSignInIfNeeded({
    String? clientId,
    String? serverClientId,
  }) async {
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
