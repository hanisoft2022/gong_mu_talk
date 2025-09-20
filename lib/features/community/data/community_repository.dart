import '../domain/entities/community_post.dart';
import '../../profile/domain/career_track.dart';

class CommunityRepository {
  CommunityRepository();

  final List<CommunityPost> _posts = <CommunityPost>[
    CommunityPost(
      id: 'post_001',
      authorName: '김하늘',
      authorTrack: CareerTrack.educationAdmin,
      content:
          '오늘은 시청에서 시민 참여 워크숍을 열었어요. 현장의 목소리가 정책으로 바로 연결되도록 준비 중입니다. 모두의 의견이 필요해요!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      likes: 42,
      comments: 8,
      audience: CommunityAudience.global,
    ),
    CommunityPost(
      id: 'post_002',
      authorName: '박서연',
      authorTrack: CareerTrack.teacher,
      content: '3학년 담임 선생님들, 이번 주 학부모 상담자료 어떻게 준비하고 계신가요? 눈높이 맞춘 안내 팁 공유해요.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      likes: 31,
      comments: 12,
      audience: CommunityAudience.track,
      targetTrack: CareerTrack.teacher,
    ),
    CommunityPost(
      id: 'post_003',
      authorName: '최민준',
      authorTrack: CareerTrack.firefighter,
      content: '부산 소방 동료들과 체력 단련 후 인증샷 📸 화재 예방 주간을 맞아 안전캠페인도 준비 중입니다.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      likes: 54,
      comments: 5,
      audience: CommunityAudience.global,
    ),
    CommunityPost(
      id: 'post_004',
      authorName: '이도윤',
      authorTrack: CareerTrack.police,
      content: '야간 순찰 중 주민 상담이 늘어서 피로도가 높네요. 교대 시간 조정해보신 분 계신가요?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
      likes: 20,
      comments: 9,
      audience: CommunityAudience.track,
      targetTrack: CareerTrack.police,
    ),
    CommunityPost(
      id: 'post_005',
      authorName: '한지우',
      authorTrack: CareerTrack.publicAdministration,
      content: '행안부 디지털 전환 TF에 합류했습니다. 공무톡에서도 디지털 업무 팁을 정리해볼게요 💡',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      likes: 67,
      comments: 15,
      audience: CommunityAudience.global,
    ),
    CommunityPost(
      id: 'post_006',
      authorName: '정유진',
      authorTrack: CareerTrack.educationAdmin,
      content: '성과평가 시즌인데, 팀 내 협업 팁이 있다면 공유 부탁드려요!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
      likes: 18,
      comments: 6,
      audience: CommunityAudience.track,
      targetTrack: CareerTrack.educationAdmin,
    ),
    CommunityPost(
      id: 'post_007',
      authorName: '오승환',
      authorTrack: CareerTrack.lawmaker,
      content: '이번 본회의에서 공무원 복지 향상 법안을 발의했습니다. 현장 의견 적극 반영할게요.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      likes: 103,
      comments: 33,
      audience: CommunityAudience.global,
    ),
  ];

  Future<List<CommunityPost>> fetchPosts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final List<CommunityPost> sorted = List<CommunityPost>.from(_posts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
