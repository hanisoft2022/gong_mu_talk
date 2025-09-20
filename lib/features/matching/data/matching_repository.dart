import 'dart:math';

import '../../profile/domain/career_track.dart';
import '../domain/entities/match_profile.dart';

class MatchRequestResult {
  const MatchRequestResult({required this.isSuccessful, required this.message});

  final bool isSuccessful;
  final String message;
}

class MatchingRepository {
  MatchingRepository();

  final List<MatchProfile> _profiles = List<MatchProfile>.unmodifiable([
    const MatchProfile(
      id: 'user_1',
      name: '김하늘',
      jobTitle: '행정사무관',
      location: '서울시청',
      yearsOfService: 8,
      introduction: '문화행정 업무를 담당하고 있어요. 주말에는 전시회를 자주 다닙니다.',
      interests: ['전시 관람', '요가', '도시 재생'],
      authorTrack: CareerTrack.publicAdministration,
    ),
    const MatchProfile(
      id: 'user_2',
      name: '이도윤',
      jobTitle: '세무서 주무관',
      location: '성동세무서',
      yearsOfService: 5,
      introduction: '동료들과 러닝 모임을 운영 중! 건강한 라이프스타일을 지향해요.',
      interests: ['러닝', '여행', '커피'],
      authorTrack: CareerTrack.publicAdministration,
    ),
    const MatchProfile(
      id: 'user_3',
      name: '박서연',
      jobTitle: '교육청 연구사',
      location: '경기도교육청',
      yearsOfService: 11,
      introduction: '미래 교육 정책을 고민합니다. 독서와 글쓰기를 즐겨요.',
      interests: ['독서', '글쓰기', '공연 관람'],
      authorTrack: CareerTrack.teacher,
    ),
    const MatchProfile(
      id: 'user_4',
      name: '최민준',
      jobTitle: '소방장',
      location: '부산소방본부',
      yearsOfService: 9,
      introduction: '강인함과 따뜻함 모두 지향합니다. 서핑과 사진 촬영이 취미예요.',
      interests: ['서핑', '사진', '맛집 탐방'],
      authorTrack: CareerTrack.firefighter,
    ),
    const MatchProfile(
      id: 'user_5',
      name: '한지우',
      jobTitle: '통계청 조사관',
      location: '통계청 본청',
      yearsOfService: 6,
      introduction: '데이터로 사회를 이해하려 노력합니다. 보드게임과 캠핑을 좋아해요.',
      interests: ['보드게임', '캠핑', '디지털 전환'],
      authorTrack: CareerTrack.publicAdministration,
    ),
    const MatchProfile(
      id: 'user_6',
      name: '서가윤',
      jobTitle: '경찰특채',
      location: '서울경찰청',
      yearsOfService: 7,
      introduction: '치안 현장을 오래 지키고 있어요. 마라톤과 악기 연주가 취미입니다.',
      interests: ['마라톤', '드럼', '범죄심리'],
      authorTrack: CareerTrack.police,
    ),
  ]);

  Future<List<MatchProfile>> fetchCandidates({
    required String currentUserId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final List<MatchProfile> candidates = _profiles
        .where((profile) => profile.id != currentUserId)
        .toList(growable: false);
    candidates.shuffle(Random());
    return candidates.take(6).toList(growable: false);
  }

  Future<MatchRequestResult> requestMatch(String candidateId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    MatchProfile? profile;
    for (final MatchProfile element in _profiles) {
      if (element.id == candidateId) {
        profile = element;
        break;
      }
    }

    if (profile == null) {
      return const MatchRequestResult(
        isSuccessful: false,
        message: '대상을 찾을 수 없습니다.',
      );
    }

    final bool success = Random().nextBool();
    if (success) {
      return MatchRequestResult(
        isSuccessful: true,
        message: '${profile.name}님과의 매칭 요청이 접수되었습니다! 24시간 내에 결과를 알려드릴게요.',
      );
    }

    return MatchRequestResult(
      isSuccessful: false,
      message: '${profile.name}님이 현재 매칭 가능 상태가 아니에요. 다른 후보에게도 신청해보세요.',
    );
  }
}
