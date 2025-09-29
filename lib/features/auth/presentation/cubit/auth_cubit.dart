import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/firebase_auth_repository.dart';
import '../../data/login_session_store.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../notifications/data/notification_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required FirebaseAuthRepository authRepository,
    required LoginSessionStore sessionStore,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _authRepository = authRepository,
       _sessionStore = sessionStore,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository,
       super(const AuthState()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      _onAuthUserChanged,
    );
  }

  final FirebaseAuthRepository _authRepository;
  final LoginSessionStore _sessionStore;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  late final StreamSubscription<AuthUser?> _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  static const Duration _sessionMaxAge = Duration(days: 30);
  String? _pendingForcedLogoutMessage;

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
      final String token = await _authRepository.requestGovernmentEmailVerification(trimmedEmail);

      // @naver.com 도메인은 실제 메일 발송, 다른 도메인은 토큰만 표시
      final String message = trimmedEmail.endsWith('@naver.com')
          ? '$trimmedEmail 로 인증 메일을 전송했습니다. 메일함을 확인하여 인증 링크를 클릭해주세요.'
          : '$trimmedEmail 인증 요청이 완료되었습니다.\n\n개발/테스트 모드 토큰: $token\n\n실제 메일 발송은 현재 공직자메일 서비스 문제로 지원되지 않습니다.';

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
          lastMessage: '공직자 메일 인증 요청에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  /// 공직자 메일 인증 토큰 검증 (개발/테스트용)
  Future<void> verifyGovernmentEmailToken(String token) async {
    try {
      final bool isValid = await _authRepository.verifyGovernmentEmailToken(token);
      if (isValid) {
        emit(state.copyWith(lastMessage: '공직자 메일 인증이 완료되었습니다!'));
        // 프로필 새로고침을 통해 업데이트된 governmentEmail 정보 반영
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

      _applyProfile(profile);

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
      emit(state.copyWith(lastMessage: '닉네임은 한 달에 한 번만 변경할 수 있어요.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));

    try {
      final UserProfile profile = await _userProfileRepository.updateNickname(
        uid: uid,
        newNickname: trimmed,
      );
      _applyProfile(profile);
      emit(state.copyWith(isProcessing: false, lastMessage: '닉네임이 변경되었습니다.'));
    } on StateError catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } on ArgumentError catch (error) {
      emit(state.copyWith(isProcessing: false, lastMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '닉네임 변경 중 오류가 발생했습니다. 다시 시도해주세요.',
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
      _applyProfile(profile);
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

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 알림 설정을 변경할 수 있습니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, notificationsEnabled: enabled);
      _applyProfile(profile);
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: enabled ? '알림을 켰습니다.' : '알림을 껐습니다.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '알림 설정을 변경하지 못했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }


  Future<void> updateSerialVisibility(bool visible) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 직렬 공개 여부를 설정할 수 있습니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, serialVisible: visible);
      _applyProfile(profile);
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: visible ? '직렬을 다시 공개합니다.' : '직렬을 비공개로 설정했습니다.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '직렬 공개 설정 변경에 실패했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> updateProfileImage({
    required Uint8List bytes,
    String? fileName,
    String contentType = 'image/jpeg',
  }) async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 프로필 이미지를 변경할 수 있습니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final String resolvedName = (fileName?.trim().isNotEmpty ?? false)
          ? fileName!.trim()
          : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String downloadUrl = await _userProfileRepository
          .uploadProfileImage(
            uid: uid,
            path: resolvedName,
            bytes: bytes,
            contentType: contentType,
          );
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, photoUrl: downloadUrl);
      _applyProfile(profile);
      emit(
        state.copyWith(isProcessing: false, lastMessage: '프로필 이미지가 변경되었습니다.'),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '프로필 이미지를 변경하지 못했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> removeProfileImage() async {
    final String? uid = state.userId;
    if (uid == null) {
      emit(state.copyWith(lastMessage: '로그인 후 프로필 이미지를 변경할 수 있습니다.'));
      return;
    }

    emit(state.copyWith(isProcessing: true, lastMessage: null));
    try {
      final UserProfile profile = await _userProfileRepository
          .updateProfileFields(uid: uid, photoUrl: null);
      _applyProfile(profile);
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '프로필 이미지를 기본 이미지로 변경했습니다.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          lastMessage: '프로필 이미지를 변경하지 못했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
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
      unawaited(_sessionStore.clearLoginTimestamp());
      _profileSubscription?.cancel();
      unawaited(_notificationRepository.stopListening());

      String? message = state.lastMessage;
      if (_pendingForcedLogoutMessage != null) {
        message = _pendingForcedLogoutMessage;
        _pendingForcedLogoutMessage = null;
      } else if (wasLoggedIn) {
        message = '로그아웃 되었습니다.';
      }

      emit(
        state.copyWith(
          isLoggedIn: false,
          userId: null,
          email: null,
          primaryEmail: null,
          isAuthenticating: false,
          isGovernmentEmailVerificationInProgress: false,
          isEmailVerified: false,
          authError: null,
          userProfile: null,
          nickname: '공무원',
          careerTrack: CareerTrack.none,
          serial: 'unknown',
          department: 'unknown',
          region: 'unknown',
          jobTitle: '직무 미입력',
          yearsOfService: 0,
          points: 0,
          level: 1,
          badges: const <String>[],
          photoUrl: null,
          nicknameChangeCount: 0,
          nicknameLastChangedAt: null,
          nicknameResetAt: null,
          extraNicknameTickets: 0,
          excludedTracks: const <CareerTrack>{},
          excludedSerials: const <String>{},
          excludedDepartments: const <String>{},
          excludedRegions: const <String>{},
          lastMessage: message,
        ),
      );
      return;
    }

    if (_sessionStore.isSessionExpired(_sessionMaxAge)) {
      _pendingForcedLogoutMessage = '보안을 위해 다시 로그인해주세요.';
      unawaited(_forceSignOut());
      return;
    }

    unawaited(_sessionStore.saveLoginTimestamp(DateTime.now()));

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

    String? message = state.lastMessage;

    emit(
      state.copyWith(
        isLoggedIn: true,
        userId: user.uid,
        email: user.email,
        primaryEmail: user.email,
        isAuthenticating: false,
        isGovernmentEmailVerificationInProgress: false,
        isEmailVerified: user.isEmailVerified,
        authError: null,
        lastMessage: message,
      ),
    );

    if (newEmail != null && _isGovernmentEmail(newEmail)) {
      unawaited(_refreshPrimaryEmail(user.uid, newEmail));
    }

    unawaited(_userProfileRepository.recordLogin(user.uid));
    _subscribeToProfile(uid: user.uid, fallbackEmail: newEmail);
    unawaited(_notificationRepository.startListening(user.uid));
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _profileSubscription?.cancel();
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
      // 로그인 액션이 성공했을 때만 메시지 설정
      emit(state.copyWith(
        isAuthenticating: false,
        lastMessage: '로그인 되었습니다.',
      ));
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

  bool _isGovernmentEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    // 임시로 @naver.com 도메인도 허용
    return normalized.endsWith('@korea.kr') || normalized.endsWith('.go.kr') || normalized.endsWith('@naver.com');
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

  void _subscribeToProfile({required String uid, String? fallbackEmail}) {
    _profileSubscription?.cancel();
    final String fallbackNickname = _deriveNickname(fallbackEmail);

    _profileSubscription = _userProfileRepository.watchProfile(uid).listen((
      UserProfile? profile,
    ) {
      if (profile == null) {
        return;
      }
      _applyProfile(profile);
    });

    unawaited(
      _userProfileRepository
          .ensureUserProfile(
            uid: uid,
            nickname: fallbackNickname,
            serial: state.serial,
            department: state.department,
            region: state.region,
            jobTitle: state.jobTitle,
            yearsOfService: state.yearsOfService,
          )
          .then(_applyProfile),
    );
  }


  void _applyProfile(UserProfile profile) {
    if (isClosed) {
      return;
    }

    final Set<CareerTrack> excludedTracks = profile.excludedSerials
        .map(_careerTrackFromSerial)
        .where((CareerTrack track) => track != CareerTrack.none)
        .toSet();

    emit(
      state.copyWith(
        userProfile: profile,
        nickname: profile.nickname,
        handle: profile.handle,
        serial: profile.serial,
        department: profile.department,
        region: profile.region,
        jobTitle: profile.jobTitle,
        yearsOfService: profile.yearsOfService,
        bio: profile.bio,
        points: profile.points,
        level: profile.level,
        badges: profile.badges,
        careerTrack: profile.careerTrack,
        photoUrl: profile.photoUrl,
        nicknameChangeCount: profile.nicknameChangeCount,
        nicknameLastChangedAt: profile.nicknameLastChangedAt,
        nicknameResetAt: profile.nicknameResetAt,
        extraNicknameTickets: profile.extraNicknameTickets,
        followerCount: profile.followerCount,
        followingCount: profile.followingCount,
        notificationsEnabled: profile.notificationsEnabled,
        serialVisible: profile.serialVisible,
        excludedTracks: excludedTracks,
        excludedSerials: profile.excludedSerials,
        excludedDepartments: profile.excludedDepartments,
        excludedRegions: profile.excludedRegions,
      ),
    );

    if (profile.notificationsEnabled) {
      final String uid = state.userId ?? profile.uid;
      unawaited(_notificationRepository.startListening(uid));
    } else {
      unawaited(_notificationRepository.stopListening());
    }
  }

  String _deriveNickname(String? email) {
    if (email == null || email.isEmpty) {
      return '공무원';
    }
    final String localPart = email.split('@').first;
    if (localPart.isEmpty) {
      return '공무원';
    }
    return localPart.length > 12 ? localPart.substring(0, 12) : localPart;
  }

  CareerTrack _careerTrackFromSerial(String serial) {
    final String normalized = serial.trim().toLowerCase();
    for (final CareerTrack track in CareerTrack.values) {
      if (track == CareerTrack.none) {
        continue;
      }
      if (normalized.contains(track.name.toLowerCase())) {
        return track;
      }
    }
    return CareerTrack.none;
  }
}
