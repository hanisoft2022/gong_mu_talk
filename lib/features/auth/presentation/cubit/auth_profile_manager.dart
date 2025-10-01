/// Extracted from auth_cubit.dart for better file organization
/// Manages user profile subscription and updates

import 'dart:async';


import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../notifications/data/notification_repository.dart';
import 'auth_cubit_helpers.dart';
import 'auth_cubit.dart';

typedef StateEmitter = void Function(AuthState);

class AuthProfileManager {
  AuthProfileManager({
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  })  : _userProfileRepository = userProfileRepository,
        _notificationRepository = notificationRepository;

  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  StreamSubscription<UserProfile?>? _profileSubscription;

  Future<void> dispose() async {
    await _profileSubscription?.cancel();
  }

  void subscribeToProfile({
    required String uid,
    String? fallbackEmail,
    required StateEmitter emit,
    required AuthState currentState,
  }) {
    _profileSubscription?.cancel();
    final String fallbackNickname = AuthCubitHelpers.deriveNickname(fallbackEmail);

    _profileSubscription = _userProfileRepository.watchProfile(uid).listen((UserProfile? profile) {
      if (profile == null) {
        return;
      }
      applyProfile(profile, emit: emit);
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
          .then((profile) => applyProfile(profile, emit: emit)),
    );
  }

  void applyProfile(
    UserProfile profile, {
    required StateEmitter emit,
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
