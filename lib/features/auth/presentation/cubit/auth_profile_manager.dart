/// Extracted from auth_cubit.dart for better file organization
/// Manages user profile subscription and updates

library;

import 'dart:async';

import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../notifications/data/notification_repository.dart';
import 'auth_cubit_helpers.dart';
import 'auth_cubit.dart';

typedef StateEmitter = void Function(AuthState);
typedef StateGetter = AuthState Function();

class AuthProfileManager {
  AuthProfileManager({
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository;

  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StateGetter? _getCurrentState;

  Future<void> dispose() async {
    await _profileSubscription?.cancel();
  }

  void subscribeToProfile({
    required String uid,
    String? fallbackEmail,
    required StateEmitter emit,
    required AuthState currentState,
    required StateGetter getCurrentState,
  }) {
    _profileSubscription?.cancel();
    _getCurrentState = getCurrentState;

    final String fallbackNickname = AuthCubitHelpers.deriveNickname(
      fallbackEmail,
    );

    _profileSubscription = _userProfileRepository.watchProfile(uid).listen((
      UserProfile? profile,
    ) {
      if (profile == null) {
        return;
      }
      // Get latest state dynamically
      applyProfile(profile, emit: emit, currentState: _getCurrentState!());
    });

    unawaited(
      _userProfileRepository
          .ensureUserProfile(
            uid: uid,
            nickname: fallbackNickname,
            serial: currentState.serial,
            department: currentState.department,
            region: currentState.region,
            jobTitle: currentState.jobTitle,
            yearsOfService: currentState.yearsOfService,
          )
          .then((profile) => applyProfile(profile, emit: emit, currentState: _getCurrentState!())),
    );
  }

  void applyProfile(
    UserProfile profile, {
    required StateEmitter emit,
    AuthState? currentState,
  }) {
    final Set<CareerTrack> excludedTracks = profile.excludedSerials
        .map(AuthCubitHelpers.careerTrackFromSerial)
        .where((CareerTrack track) => track != CareerTrack.none)
        .toSet();

    emit(
      AuthState(
        isLoggedIn: true,
        userId: profile.uid,
        email: profile.uid,
        primaryEmail: profile.uid,
        isEmailVerified: false,
        isPasswordProvider: currentState?.isPasswordProvider ?? true,
        userProfile: profile,
        nickname: profile.nickname,
        handle: profile.handle,
        serial: profile.serial,
        department: profile.department,
        region: profile.region,
        jobTitle: profile.jobTitle,
        yearsOfService: profile.yearsOfService,
        bio: profile.bio,
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
        careerHierarchy: profile.careerHierarchy,
      ),
    );

    if (profile.notificationsEnabled) {
      unawaited(_notificationRepository.startListening(profile.uid));
    } else {
      unawaited(_notificationRepository.stopListening());
    }
  }
}
