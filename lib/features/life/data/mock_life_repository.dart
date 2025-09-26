import 'dart:async';
import 'dart:math';

import '../../community/data/mock_social_graph.dart';
import '../domain/life_meeting.dart';

class MockLifeRepository {
  MockLifeRepository({MockSocialGraph? socialGraph})
    : _socialGraph = socialGraph ?? MockSocialGraph() {
    _controller = StreamController<List<LifeMeeting>>.broadcast(onListen: _emit);
    _meetings = <LifeMeeting>[
      LifeMeeting(
        id: 'meet_${Random().nextInt(999999)}',
        category: MeetingCategory.running,
        title: '한강 러닝 크루 주말 오전 모임',
        description: '토요일 오전 7시에 뚝섬에서 모여 7km 함께 달립니다. 이후 브런치 예정!',
        host: const MeetingMember(uid: 'lee.jisoo', nickname: '이지수'),
        capacity: 12,
        members: const <MeetingMember>[
          MeetingMember(uid: 'lee.jisoo', nickname: '이지수'),
          MeetingMember(uid: 'park.haneul', nickname: '박하늘'),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        schedule: DateTime.now().add(const Duration(days: 3, hours: 7)),
        location: '뚝섬 자벌레 앞',
        tags: const <String>['러닝', '건강', '브런치'],
      ),
      LifeMeeting(
        id: 'meet_${Random().nextInt(999999)}',
        category: MeetingCategory.boardGame,
        title: '은평 보드게임 밤 번개',
        description: '테라포밍마스, 위너스 서클 등 전략 게임 함께 즐길 분 구해요.',
        host: const MeetingMember(uid: 'park.haneul', nickname: '박하늘'),
        capacity: 6,
        members: const <MeetingMember>[MeetingMember(uid: 'park.haneul', nickname: '박하늘')],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        schedule: DateTime.now().add(const Duration(days: 5, hours: 19)),
        location: '은평구 불광역 보드게임카페',
        tags: const <String>['보드게임', '번개'],
      ),
      LifeMeeting(
        id: 'meet_${Random().nextInt(999999)}',
        category: MeetingCategory.realEstateTour,
        title: '부동산 임장 · 구리 갈매 신도시',
        description: '토지이용계획 함께 분석하고 신축 단지 살펴봐요. 교통편 공유 예정.',
        host: const MeetingMember(uid: 'choi.minsu', nickname: '최민수'),
        capacity: 10,
        members: const <MeetingMember>[MeetingMember(uid: 'choi.minsu', nickname: '최민수')],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        schedule: DateTime.now().add(const Duration(days: 10, hours: 10)),
        location: '갈매역 2번 출구 집결',
        tags: const <String>['부동산', '현장답사'],
      ),
    ];
    _emit();
  }

  final MockSocialGraph _socialGraph;
  late final StreamController<List<LifeMeeting>> _controller;
  late List<LifeMeeting> _meetings;

  Stream<List<LifeMeeting>> watchMeetings() => _controller.stream;

  Future<LifeMeeting> createMeeting({
    required MeetingCategory category,
    required String title,
    required String description,
    required MeetingMember host,
    required int capacity,
    String? location,
    DateTime? schedule,
    List<String>? tags,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final LifeMeeting meeting = LifeMeeting(
      id: 'meet_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      category: category,
      title: title,
      description: description,
      host: host,
      capacity: capacity,
      members: <MeetingMember>[host],
      createdAt: DateTime.now(),
      location: location,
      schedule: schedule,
      tags: tags ?? const <String>[],
    );
    _meetings = <LifeMeeting>[meeting, ..._meetings];
    _emit();
    return meeting;
  }

  Future<LifeMeeting> joinMeeting({
    required String meetingId,
    required MeetingMember member,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int index = _meetings.indexWhere((LifeMeeting meeting) => meeting.id == meetingId);
    if (index == -1) {
      throw StateError('모임을 찾을 수 없습니다.');
    }
    final LifeMeeting current = _meetings[index];
    if (current.members.any((MeetingMember element) => element.uid == member.uid)) {
      return current;
    }
    if (current.members.length >= current.capacity) {
      throw StateError('모집이 마감된 모임입니다.');
    }
    final LifeMeeting updated = current.copyWith(
      members: <MeetingMember>[...current.members, member],
    );
    _meetings[index] = updated;
    _emit();
    return updated;
  }

  List<MeetingMember> suggestedFriends() {
    return _socialGraph.allProfiles
        .map(
          (MockMemberProfileData profile) =>
              MeetingMember(uid: profile.uid, nickname: profile.nickname),
        )
        .toList(growable: false);
  }

  void _emit() {
    _controller.add(List<LifeMeeting>.unmodifiable(_meetings));
  }

  void dispose() {
    _controller.close();
  }
}
