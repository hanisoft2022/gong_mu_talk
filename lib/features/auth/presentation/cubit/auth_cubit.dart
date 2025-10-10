/// Refactored to meet AI token optimization guidelines
/// Main auth cubit - extracted helper methods to separate files
/// Target: ≤300 lines (logic file guideline)

library;

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase_auth_repository.dart';
import '../../data/login_session_store.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/career_hierarchy.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../notifications/data/notification_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/profile_storage_service.dart';
import '../../../calculator/domain/entities/feature_access_level.dart';
import 'auth_cubit_helpers.dart';
import 'auth_profile_manager.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required FirebaseAuthRepository authRepository,
    required LoginSessionStore sessionStore,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
    required NotificationService notificationService,
    required ProfileStorageService profileStorageService,
    required SharedPreferences sharedPreferences,
  }) : _authRepository = authRepository,
       _sessionStore = sessionStore,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository,
       _notificationService = notificationService,
       _profileStorageService = profileStorageService,
       _sharedPreferences = sharedPreferences,
       _profileManager = AuthProfileManager(
         userProfileRepository: userProfileRepository,
         notificationRepository: notificationRepository,
       ),
       super(const AuthState()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onAuthUserChanged,
    );
  }

  final FirebaseAuthRepository _authRepository;
  final LoginSessionStore _sessionStore;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  final NotificationService _notificationService;
  final ProfileStorageService _profileStorageService;
  final SharedPreferences _sharedPreferences;
  final AuthProfileManager _profileManager;
  late final StreamSubscription<AuthUser?> _authSubscription;
  static const Duration _sessionMaxAge = Duration(days: 30);
  String? _pendingForcedLogoutMessage;

  // Authentication operations
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

  Future<void> logOut() async {
    try {
      await _authRepository.signOut();
    } on AuthException catch (error) {
      emit(state.copyWith(authError: error.message));
    } catch (_) {
      emit(state.copyWith(authError: '로그아웃에 실패했습니다. 잠시 후 다시 시도해주세요.'));
    }
  }

  // Government email verification
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
      final String token = await _authRepository
          .requestGovernmentEmailVerification(trimmedEmail);

      final String message = trimmedEmail.endsWith('@naver.com')
          ? '$trimmedEmail 로 인증 메일을 전송했습니다. 메일함을 확인하여 인증 링크를 클릭해주세요.'
          : '$trimmedEmail 인증 요청이 완료되었습니다.\n\n개발/테스트 모드 토큰: $token\n\n실제 메일 발송은 현재 해당 도메인에서 지원되지 않습니다.';

      emit(
        state.copyWith(
          isGovernmentEmailVerificationInProgress: false,
          lastMessage: message,
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isGovernmentEmailVerificationInProgress: false,
          lastMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isGovernmentEmailVerificationInProgress: false,
          lastMessage: '공직자 통합 메일 인증 요청에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> verifyGovernmentEmailToken(String token) async {
    try {
      final bool isValid = await _authRepository.verifyGovernmentEmailToken(
        token,
      );
      if (isValid) {
        emit(state.copyWith(lastMessage: '공직자 메일 인증이 완료되었습니다!'));
        await refreshAuthStatus();
      } else {
        emit(state.copyWith(lastMessage: '유효하지 않거나 만료된 토큰입니다.'));
      }
    } catch (error) {
      emit(state.copyWith(lastMessage: '토큰 검증 중 오류가 발생했습니다.'));
    }
  }

  void clearGovernmentEmailVerificationForTesting() {
    emit(
      state.copyWith(
        isEmailVerified: false,
        lastMessage: '개발용 인증 상태가 초기화되었습니다.',
      ),
    );
  }

  Future<void> refreshAuthStatus() async {
    await _authRepository.reloadCurrentUser();
    final AuthUser? user = _authRepository.currentAuthUser;
    _onAuthUserChanged(user);
  }

  // Profile update operations
  Future<void> updateCareerTrack(CareerTrack track) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 직렬을 설정할 수 있습니다.'));
      return;
    }

    try {
      final String serial = track == CareerTrack.none ? 'unknown' : track.name;
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, careerTrack: track, serial: serial);

      _profileManager.applyProfile(profile, emit: emit, currentState: state);

      final String message = track == CareerTrack.none
          ? '직렬 설정이 초기화되었습니다.'
          : '직렬이 ${track.displayName}로 설정되었습니다.';
      emit(state.copyWith(lastMessage: message));
    } catch (_) {
      emit(state.copyWith(lastMessage: '직렬 설정에 실패했습니다. 잠시 후 다시 시도해주세요.'));
    }
  }

  Future<void> updateNickname(String newNickname) async {
    final String trimmed = newNickname.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(lastMessage: '닉네임을 입력해주세요.'));
      return;
    }

    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 닉네임을 변경할 수 있습니다.'));
      return;
    }

    if (!state.canChangeNickname) {
      emit(state.copyWith(lastMessage: '닉네임은 30일마다 변경할 수 있어요.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));

    try {
      final UserProfile profile = await _userProfileRepository.updateNickname(
        uid: uid,
        newNickname: trimmed,
      );
      _profileManager.applyProfile(profile, emit: emit, currentState: state);
      emit(state.copyWith(isProcessing: false, lastMessage: '닉네임이 변경되었습니다.'));
    } on StateError catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } on ArgumentError catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '닉네임 변경 중 오류가 발생했습니다: $error',
        ),
      );
    }
  }

  Future<void> updateBio(String bio) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 자기소개를 수정할 수 있습니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final String trimmed = bio.trim();
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, bio: trimmed.isEmpty ? null : trimmed);
      _profileManager.applyProfile(profile, emit: emit, currentState: state);
      emit(state.copyWith(isProcessing: false, lastMessage: '자기소개를 업데이트했습니다.'));
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '자기소개를 업데이트하지 못했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  /// 디버그/테스트용: 닉네임 변경 제한 초기화
  Future<void> resetNicknameChangeLimit() async {
    final String? uid = state.userId;
    if (uid == null) {
      return;
    }

    try {
      final UserProfile profile =
          await _userProfileRepository.resetNicknameChangeLimit(uid: uid);
      _profileManager.applyProfile(profile, emit: emit, currentState: state);
      emit(state.copyWith(lastMessage: '닉네임 변경 제한이 초기화되었습니다.'));
    } catch (_) {
      emit(state.copyWith(lastMessage: '제한 초기화에 실패했습니다.'));
    }
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final String? uid = state.userId;
    if (uid == null) {
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, notificationsEnabled: enabled);
      _profileManager.applyProfile(profile, emit: emit, currentState: state);
      emit(state.copyWith(isProcessing: false));
    } catch (_) {
      emit(state.copyWith(isProcessing: false));
    }
  }

  Future<void> updateSerialVisibility(bool visible) async {
    final String? uid = state.userId;
    if (uid == null) {
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, serialVisible: visible);
      _profileManager.applyProfile(profile, emit: emit, currentState: state);
      emit(state.copyWith(isProcessing: false));
    } catch (_) {
      emit(state.copyWith(isProcessing: false));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(state.copyWith(isProcessing: false, lastMessage: '비밀번호를 변경했습니다.'));
    } on AuthException catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '비밀번호 변경에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> deleteAccount({String? currentPassword}) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 탈퇴를 진행할 수 있습니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      await _authRepository.deleteAccount(currentPassword: currentPassword);
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '계정을 삭제했습니다. 다시 만나길 바랄게요.',
        ),
      );
    } on AuthException catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '회원 탈퇴 처리에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> toggleExcludedTrack(CareerTrack track) async {
    final Set<CareerTrack> updated = Set<CareerTrack>.from(
      state.excludedTracks,
    );
    if (!updated.remove(track)) {
      updated.add(track);
    }

    emit(
      state.copyWith(
        excludedTracks: updated,
        excludedSerials: updated.map((CareerTrack track) => track.name).toSet(),
      ),
    );

    final String? uid = state.userId;
    if (uid == null) {
      emit(
        state.copyWith(
          excludedTracks: updated,
          lastMessage: '로그인 후 제외 직렬을 설정할 수 있습니다.',
        ),
      );
      return;
    }

    try {
      await _userProfileRepository.updateExclusionSettings(
        uid: uid,
        excludedSerials: updated.map((CareerTrack track) => track.name).toSet(),
      );
      emit(
        state.copyWith(
          excludedTracks: updated,
          excludedSerials: updated
              .map((CareerTrack track) => track.name)
              .toSet(),
          lastMessage: '매칭 제외 직렬 설정이 업데이트되었습니다.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          excludedTracks: updated,
          excludedSerials: updated
              .map((CareerTrack track) => track.name)
              .toSet(),
          lastMessage: '매칭 제외 직렬 설정에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  void _onAuthUserChanged(AuthUser? user) {
    final bool wasLoggedIn = state.isLoggedIn;

    if (user == null) {
      _handleLogout(wasLoggedIn);
      return;
    }

    if (_sessionStore.isSessionExpired(_sessionMaxAge)) {
      _pendingForcedLogoutMessage = '보안을 위해 다시 로그인해주세요.';
      unawaited(_forceSignOut());
      return;
    }

    unawaited(_sessionStore.saveLoginTimestamp(DateTime.now()));
    _handleLogin(user);
  }

  void _handleLogout(bool wasLoggedIn) {
    final String? userId = state.userId;

    unawaited(_sessionStore.clearLoginTimestamp());
    unawaited(_notificationRepository.stopListening());

    // 🔐 Security: Clear user-specific local data on logout
    // 1. Calculator profile data
    unawaited(_profileStorageService.clearProfile(userId: userId));

    // 2. Notification settings
    unawaited(_notificationRepository.clearNotificationSettings(userId: userId));

    // 3. Search history (recent searches)
    unawaited(_clearSearchHistory(userId));

    String? message = state.lastMessage;
    if (_pendingForcedLogoutMessage != null) {
      message = _pendingForcedLogoutMessage;
      _pendingForcedLogoutMessage = null;
    } else if (wasLoggedIn) {
      message = '로그아웃 되었습니다.';
    }

    emit(AuthState(lastMessage: message));
  }

  /// Clear search history for specific user
  Future<void> _clearSearchHistory(String? userId) async {
    // SearchCubit의 key 패턴과 동일하게 구현
    const String recentSearchesKeyPrefix = 'recent_searches';
    const String guestSearchesKey = 'recent_searches_guest';

    final String key;
    if (userId == null || userId.isEmpty) {
      key = guestSearchesKey;
    } else {
      key = '${recentSearchesKeyPrefix}_$userId';
    }

    await _sharedPreferences.remove(key);
  }

  void _handleLogin(AuthUser user) {
    final String? previousEmail = state.email;
    final String? newEmail = user.email;
    if (newEmail != null && newEmail.isNotEmpty) {
      if (previousEmail != null &&
          previousEmail.isNotEmpty &&
          previousEmail != newEmail) {
        unawaited(
          _authRepository.handlePrimaryEmailUpdated(
            userId: user.uid,
            previousEmail: previousEmail,
            newEmail: newEmail,
          ),
        );
      } else {
        unawaited(
          _authRepository.ensureGovernmentEmailRecord(
            userId: user.uid,
            email: newEmail,
            isEmailVerified: user.isEmailVerified,
          ),
        );
      }
    }

    emit(
      state.copyWith(
        isLoggedIn: true,
        userId: user.uid,
        email: user.email,
        primaryEmail: user.email,
        isAuthenticating: false,
        isGovernmentEmailVerificationInProgress: false,
        isEmailVerified: user.isEmailVerified,
        isPasswordProvider: user.isPasswordProvider,
        authError: null,
        lastMessage: state.lastMessage,
      ),
    );

    if (newEmail != null && AuthCubitHelpers.isGovernmentEmail(newEmail)) {
      unawaited(_refreshPrimaryEmail(user.uid, newEmail));
    }

    unawaited(_userProfileRepository.recordLogin(user.uid));
    _profileManager.subscribeToProfile(
      uid: user.uid,
      fallbackEmail: newEmail,
      emit: emit,
      currentState: state,
      getCurrentState: () => state,
    );
    unawaited(_notificationRepository.startListening(user.uid));

    // Save FCM token to Firestore for push notifications
    unawaited(_saveFcmToken(user.uid));
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final String? token = await _notificationService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is null or empty, skipping save');
        return;
      }

      await _userProfileRepository.updateProfileFields(
        uid: uid,
        fcmToken: token,
      );
      debugPrint('FCM token saved successfully for user: $uid');
    } catch (error, stackTrace) {
      debugPrint('Failed to save FCM token: $error\n$stackTrace');
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _profileManager.dispose();
    await _notificationRepository.stopListening();
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
      emit(state.copyWith(isAuthenticating: false, lastMessage: '로그인 되었습니다.'));
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

  void clearLastMessage() {
    if (state.lastMessage == null) {
      return;
    }
    emit(state.copyWith(lastMessage: null));
  }

  Future<void> _refreshPrimaryEmail(
    String userId,
    String governmentEmail,
  ) async {
    try {
      final String? legacyEmail = await _authRepository
          .findLegacyEmailForGovernmentEmail(
            userId: userId,
            governmentEmail: governmentEmail,
          );

      if (legacyEmail == null || legacyEmail.isEmpty) {
        return;
      }

      if (isClosed) {
        return;
      }

      if (state.primaryEmail == legacyEmail) {
        return;
      }

      emit(state.copyWith(primaryEmail: legacyEmail));
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to resolve primary email for $governmentEmail: $error\n$stackTrace',
      );
    }
  }
}
