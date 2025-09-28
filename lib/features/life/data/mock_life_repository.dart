// Temporary stub to prevent compilation errors
// This will be fully removed in a future update

import '../../../features/community/data/mock_social_graph.dart';
import '../domain/life_meeting.dart';

class MockLifeRepository {
  MockLifeRepository({required MockSocialGraph socialGraph});

  Stream<List<LifeMeeting>> watchMeetings() {
    return Stream.value([]);
  }

  Future<void> joinMeeting({
    required String meetingId,
    required MeetingMember member,
  }) async {
    // Empty stub implementation
  }

  Future<void> createMeeting({
    required MeetingCategory category,
    required String title,
    required String description,
    required MeetingMember host,
    required int capacity,
    String? location,
    DateTime? schedule,
  }) async {
    // Empty stub implementation
  }
}