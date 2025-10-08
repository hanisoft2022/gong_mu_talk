/// Banned words for nickname validation
///
/// Categories:
/// 1. Admin impersonation
/// 2. Political terms
/// 3. Profanity (normal level)
/// 4. Hate speech
/// 5. System reserved words
/// 6. Pattern matching for variations
library;

class BannedWords {
  BannedWords._();

  // ===== 1. 관리자 사칭 =====
  static const List<String> adminImpersonation = [
    // 한글
    '운영자',
    '운영진',
    '관리자',
    '매니저',
    '마스터',
    '공무톡운영',
    '공무톡관리자',
    // 영문
    'admin',
    'administrator',
    'manager',
    'master',
    'moderator',
    'mod',
    'gm',
    'staff',
  ];

  // ===== 2. 정치 관련 =====
  static const List<String> political = [
    // 정당
    '더불어민주당',
    '민주당',
    '국민의힘',
    '정의당',
    '개혁신당',
    '진보당',
    '새로운미래',
    '기본소득당',
    '민주',
    '국힘',
    '여당',
    '야당',
    // 과거 정당
    '새누리당',
    '자유한국당',
    '미래통합당',
    '국민의당',
    '바른미래당',
    // 정치인 (풀네임만, 성 제외)
    '윤석열',
    '문재인',
    '박근혜',
    '이명박',
    '노무현',
    '이재명',
    '한동훈',
    '김동연',
    '조국',
    '추미애',
    '나경원',
    '심상정',
    // 정치 용어
    '좌파',
    '우파',
    '진보',
    '보수',
    '빨갱이',
    '수구',
    '종북',
  ];

  // ===== 3. 욕설/비속어 (보통 수준) =====
  static const List<String> profanity = [
    // 한글 기본 욕설
    '씨발',
    '시발',
    '씨빨',
    'ㅅㅂ',
    'ㅆㅂ',
    '개새',
    '개세',
    '개색',
    '개쉑',
    '개새끼',
    '병신',
    '븅신',
    'ㅂㅅ',
    '지랄',
    'ㅈㄹ',
    '좆',
    '좃',
    '조까',
    'ㅈㄲ',
    '엿먹어',
    '꺼져',
    '닥쳐',
    // 성적 표현
    '보지',
    '자지',
    '섹스',
    '성교',
    '야동',
    '포르노',
    // 영문 욕설
    'fuck',
    'shit',
    'bitch',
    'ass',
    'dick',
    'pussy',
    'cock',
  ];

  // ===== 4. 혐오 표현 =====
  static const List<String> hate = [
    // 성별 비하
    '한남',
    '한녀',
    '김치녀',
    '된장녀',
    '보슬아치',
    '걸레',
    '창녀',
    // 장애 비하
    '장애인',
    '정신병',
    '애자',
    '장애자',
    // 국적/인종 비하
    '흑형',
    '짱깨',
    '쪽바리',
    '양키',
  ];

  // ===== 5. 시스템 예약어 =====
  static const List<String> system = [
    // 한글
    '시스템',
    '알림',
    '탈퇴',
    '삭제',
    '차단',
    '공지',
    // 영문
    'system',
    'notification',
    'deleted',
    'removed',
    'banned',
    'blocked',
    'notice',
    'announcement',
    // 테스트
    '테스트',
    '임시',
    'test',
    'temp',
    'temporary',
  ];

  // ===== 6. 광고성 (선택적) =====
  static const List<String> advertisement = [
    '광고',
    '홍보',
    '협찬',
    '마케팅',
    '구매',
    '판매',
    '영업',
    'ad',
    'ads',
    'promo',
    'sponsor',
    'sales',
  ];

  // ===== 변형 감지 패턴 =====
  static final List<RegExp> patterns = [
    RegExp(r'[씨시][발빨]'), // 씨발, 시발
    RegExp(r'개[새세색쉑]'), // 개새끼
    RegExp(r'[병븅][신씬]'), // 병신
    RegExp(r'[좆좃][같까]'), // 좆같아, 좆까
    RegExp(r'(운영|관리)(자|팀|진)'), // 운영자, 관리팀
    RegExp(r'admin|moderator', caseSensitive: false), // admin, moderator
  ];

  // ===== 모든 금지 단어 통합 =====
  static List<String> get all => [
        ...adminImpersonation,
        ...political,
        ...profanity,
        ...hate,
        ...system,
        // advertisement는 선택적으로 제외 (너무 제한적일 수 있음)
      ];
}
