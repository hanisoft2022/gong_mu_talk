import '../../profile/domain/career_track.dart';

/// Abstraction over the active user session so infrastructure layers
/// avoid depending on presentation concerns.
abstract interface class UserSession {
  String get userId;

  CareerTrack get careerTrack;

  String? get specificCareer;

  int get supporterLevel;

  bool get serialVisible;
}
