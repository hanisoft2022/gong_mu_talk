import '../domain/entities/blind_post.dart';

class BlindRepository {
  BlindRepository();

  final List<BlindPost> _posts = <BlindPost>[
    BlindPost(
      id: 'blind_001',
      title: '인사이동 소식',
      content: '이번 분기 인사이동 대상자 발표가 곧 나온다는데... 다들 어떤 소식 들으셨나요? 저는 교육청 본청으로 발령 나면 좋겠는데 긴장됩니다.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      likes: 58,
      comments: 23,
      department: '교육청',
    ),
    BlindPost(
      id: 'blind_002',
      title: '야근 수당',
      content: '야근수당 누락된 거 뒤늦게 발견했어요. 회계팀에 문의했는데 다음달 반영한다네요. 비슷한 경험 있으신가요?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 14)),
      likes: 34,
      comments: 12,
      department: '행정안전부',
    ),
    BlindPost(
      id: 'blind_003',
      title: '경찰청 워라밸',
      content: '경찰청 본청 근무 중인데, 야간 상황실 근무가 너무 자주 돌아와요. 다른 부서도 이런가요?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 21)),
      likes: 44,
      comments: 18,
      department: '경찰청',
    ),
    BlindPost(
      id: 'blind_004',
      title: '국회 식당 리모델링',
      content: '국회 구내식당 새로 단장한다네요. 메뉴 다양해지면 좋겠어요. 혹시 제안하고 싶은 메뉴 있으신가요?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      likes: 21,
      comments: 7,
      department: '국회',
    ),
    BlindPost(
      id: 'blind_005',
      title: '소방 근무복',
      content: '여름용 근무복이 너무 더워요. 현장 동료들 의견 모아서 본부에 개선 요청하려고 합니다. 공감하시는 분?',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      likes: 63,
      comments: 19,
      department: '소방청',
    ),
    BlindPost(
      id: 'blind_006',
      title: '로테이션 희망',
      content: '지방국세청 조사국 근무 중인데 본청 법인세국으로 이동하고 싶은데 팁 있을까요? 면접 준비 어떻게 하셨는지 공유 부탁드려요.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
      likes: 27,
      comments: 11,
      department: '국세청',
    ),
  ];

  Future<List<BlindPost>> fetchPosts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final List<BlindPost> sorted = List<BlindPost>.from(_posts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
