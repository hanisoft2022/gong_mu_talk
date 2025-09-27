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
    return '직렬 비공개';
  }
  if (!includeEmoji) {
    return track.displayName;
  }
  return '${track.emoji} ${track.displayName}';
}

String maskNickname(String source) {
  final String normalized = source.trim();
  if (normalized.isEmpty) {
    return '공***';
  }
  final int firstCodePoint = normalized.runes.first;
  final String firstCharacter = String.fromCharCode(
    firstCodePoint,
  ).toUpperCase();
  return '$firstCharacter***';
}
