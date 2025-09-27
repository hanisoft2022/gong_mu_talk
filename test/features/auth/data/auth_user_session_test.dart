import 'package:flutter_test/flutter_test.dart';

import 'package:gong_mu_talk/features/auth/data/auth_user_session.dart';
import 'package:gong_mu_talk/features/auth/domain/user_session.dart';
import 'package:gong_mu_talk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gong_mu_talk/features/profile/domain/career_track.dart';

void main() {
  group('AuthUserSession', () {
    AuthState buildState({
      String? userId,
      CareerTrack track = CareerTrack.teacher,
      int supporterLevel = 1,
      bool serialVisible = true,
    }) {
      return AuthState(
        userId: userId,
        careerTrack: track,
        supporterLevel: supporterLevel,
        serialVisible: serialVisible,
        isLoggedIn: userId != null,
      );
    }

    test('exposes persisted values from provided state', () {
      final AuthState state = buildState(userId: 'user-1');
      final UserSession session = AuthUserSession.fromStateProvider(
        () => state,
      );

      expect(session.userId, 'user-1');
      expect(session.careerTrack, CareerTrack.teacher);
      expect(session.supporterLevel, 1);
      expect(session.serialVisible, isTrue);
    });

    test('falls back to anonymous identifier when state is empty', () {
      final AuthState state = buildState(userId: null);
      final UserSession session = AuthUserSession.fromStateProvider(
        () => state,
      );

      expect(session.userId, 'anonymous');
    });
  });
}
