import '../../../profile/domain/career_track.dart';

String serialLabel(
  CareerTrack track,
  bool serialVisible, {
  bool includeEmoji = true,
}) {
  if (!serialVisible) {
    return '공무원';
  }
  if (track == CareerTrack.none) {
    return '공무원';  // 직렬 정보가 없을 때는 "공무원"으로 표시
  }
  if (!includeEmoji) {
    return track.displayName;
  }
  return '${track.emoji} ${track.displayName}';
}

/// 반익명 시스템: 직렬 + 닉네임 통합 표시
///
/// 예시:
/// - 직렬 공개: "초등교사 김선생"
/// - 직렬 숨김: "공무원 김선생"
String getDisplayName({
  required String nickname,
  required CareerTrack track,
  required bool serialVisible,
}) {
  final String trackLabel = serialVisible && track != CareerTrack.none
      ? track.displayName
      : '공무원';

  return '$trackLabel $nickname';
}
