/// Extracted from auth_cubit.dart for better file organization
/// Helper methods for auth cubit operations

library;

import '../../../profile/domain/career_track.dart';

class AuthCubitHelpers {
  const AuthCubitHelpers._();

  static String deriveNickname(String? email) {
    if (email == null || email.isEmpty) {
      return '공무원';
    }
    final String localPart = email.split('@').first;
    if (localPart.isEmpty) {
      return '공무원';
    }
    return localPart.length > 12 ? localPart.substring(0, 12) : localPart;
  }

  static CareerTrack careerTrackFromSerial(String serial) {
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

  static bool isGovernmentEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    // 임시로 @naver.com 도메인도 허용
    return normalized.endsWith('@korea.kr') ||
        normalized.endsWith('.go.kr') ||
        normalized.endsWith('@naver.com');
  }
}
