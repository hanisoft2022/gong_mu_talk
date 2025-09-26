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
  MockSocialGraph()
    : _profiles = <String, MockMemberProfileData>{
        'lee.jisoo': const MockMemberProfileData(
          uid: 'lee.jisoo',
          nickname: '이지수',
          track: CareerTrack.educationAdmin,
          department: '서울시교육청',
          region: '서울 양천구',
          bio: '초등학교 6학년 담임. 주말엔 러닝과 보드게임을 즐겨요.',
          tags: <String>['러닝', '보드게임', '수업연구'],
          recentPosts: <String>[
            '새 학기 아이들과 함께한 흙놀이 프로젝트 후기 공유합니다.',
            '학부모 상담에서 유용했던 질문 리스트 정리했어요.',
          ],
        ),
        'park.haneul': const MockMemberProfileData(
          uid: 'park.haneul',
          nickname: '박하늘',
          track: CareerTrack.publicAdministration,
          department: '행정안전부',
          region: '세종특별자치시',
          bio: '정부청사 재난안전과 근무. 배드민턴 동호회 운영 중입니다.',
          tags: <String>['안전', '배드민턴', '캠핑'],
          recentPosts: <String>[
            '정부청사 배드민턴 동호회 신규 회원 모집합니다!',
            '캠핑 장비 공유 노하우 정리해봤어요.',
          ],
        ),
        'choi.minsu': const MockMemberProfileData(
          uid: 'choi.minsu',
          nickname: '최민수',
          track: CareerTrack.police,
          department: '경기남부경찰청',
          region: '경기 수원시',
          bio: '생활안전계 근무. 주말엔 헬스와 러닝으로 체력관리!',
          tags: <String>['헬스', '러닝', '안전교육'],
          recentPosts: <String>[
            '교통안전 교육 자료, 초등학교용으로 정리해봤습니다.',
            '러닝 크루 새벽 모임 함께 하실 분 계신가요?',
          ],
        ),
      };

  final Map<String, MockMemberProfileData> _profiles;
  final Set<String> _following = <String>{};

  Iterable<MockMemberProfileData> get allProfiles => _profiles.values;

  MockMemberProfileData? getProfile(String uid) => _profiles[uid];

  bool isFollowing(String uid) => _following.contains(uid);

  Future<bool> toggleFollow(String uid, {bool? shouldFollow}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final bool willFollow = shouldFollow ?? !_following.contains(uid);
    if (willFollow) {
      _following.add(uid);
    } else {
      _following.remove(uid);
    }
    return willFollow;
  }
}
