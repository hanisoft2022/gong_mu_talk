// Temporary stub to prevent compilation errors
// This will be fully removed in a future update

import '../../profile/domain/career_track.dart';

class MockMemberProfileData {
  const MockMemberProfileData({
    required this.uid,
    required this.nickname,
    required this.track,
    required this.department,
    required this.region,
    required this.bio,
    required this.tags,
    required this.recentPosts,
  });

  final String uid;
  final String nickname;
  final CareerTrack track;
  final String department;
  final String region;
  final String bio;
  final List<String> tags;
  final List<String> recentPosts;
}

class MockSocialGraph {
  MockSocialGraph();

  MockMemberProfileData? getProfile(String uid) => null;

  bool isFollowing(String uid) => false;

  Future<bool> toggleFollow(String uid, {bool? shouldFollow}) async {
    return false;
  }
}
