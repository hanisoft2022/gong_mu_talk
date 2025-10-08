/// Privacy Policy Page
///
/// Displays the privacy policy within the app.
///
/// **Purpose**:
/// - Show privacy policy without external browser
/// - Required for app store compliance (Google Play, App Store)
/// - Allow users to review data handling practices
///
/// **Content**:
/// - Data collection practices (actual data collected)
/// - Data usage and storage (Firebase services)
/// - User rights (GDPR compliance)
/// - Contact information
///
/// **Last Updated**: 2025년 1월 8일

library;

import 'package:flutter/material.dart';

/// Privacy policy page
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 처리방침'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              '공무톡 개인정보 처리방침',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '최종 수정일: 2025년 1월 8일\n시행일: 2025년 1월 8일',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Content
            _buildSection(
              theme,
              title: '1. 개인정보 처리방침의 의의',
              content: '''
공무톡(이하 "서비스")을 운영하는 HANISOFT(이하 "회사")는 「개인정보 보호법」, 「정보통신망 이용촉진 및 정보보호 등에 관한 법률」 등 관련 법령에 따라 이용자의 개인정보를 보호하고, 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 다음과 같이 개인정보 처리방침을 수립·공개합니다.
''',
            ),

            _buildSection(
              theme,
              title: '2. 수집하는 개인정보의 항목 및 수집방법',
              content: '''
회사는 서비스 제공을 위해 아래와 같이 개인정보를 수집합니다.

【 회원가입 시 수집하는 필수 항목 】
  • 이메일 주소 (계정 생성 및 본인 확인)
  • 비밀번호 (암호화하여 저장)
  • 닉네임 (커뮤니티 활동 시 표시명)
  • 직렬 정보 (예: 일반직, 교육직, 소방직 등)
  • 직급 정보 (예: 6급, 7급, 교사 등)
  • 부서 정보 (예: 행정, 기술 등)
  • 지역 정보 (예: 서울, 부산 등)
  • 재직 기간 (연차 계산용)

【 선택 항목 】
  • 자기소개 (프로필에 표시되는 간단한 소개)
  • 관심사 (추천 기능 개선용)
  • 공직자 이메일 주소 (정부기관 인증용, @korea.kr, @*.go.kr)

【 서비스 이용 과정에서 자동으로 수집되는 정보 】
  • 서비스 이용 기록 (접속 로그, 게시글/댓글 작성, 좋아요, 스크랩, 팔로우 기록)
  • 기기 정보 (OS 종류 및 버전, 앱 버전)
  • IP 주소 (보안 및 부정 사용 방지)
  • 쿠키 및 세션 정보 (자동 로그인)
  • Firebase Analytics 데이터 (화면 조회, 앱 사용 패턴 등 익명화된 통계)
  • Firebase Performance Monitoring 데이터 (앱 성능 측정용)
  • Crashlytics 오류 로그 (앱 안정성 개선용)

【 게시글/댓글 작성 시 수집 】
  • 게시글 본문 (텍스트)
  • 업로드한 이미지 (Firebase Storage에 저장, 자동 압축 및 썸네일 생성)
  • 작성 시각, 수정 시각

【 수집하지 않는 항목 】
  • 프로필 사진 (현재 버전에서는 지원하지 않음)
  • 실명 (반익명 시스템)
  • 주민등록번호, 여권번호 등 민감정보
  • 전화번호
  • 위치 정보 (GPS)

【 수집 방법 】
  • 회원가입 및 서비스 이용 시 이용자가 직접 입력
  • Google Sign-In을 통한 소셜 로그인 (이메일 주소만 수집)
  • 앱 내 자동 수집 (Firebase SDK)
''',
            ),

            _buildSection(
              theme,
              title: '3. 개인정보의 수집 및 이용 목적',
              content: '''
회사는 수집한 개인정보를 다음의 목적을 위해 활용합니다.

【 회원 관리 】
  • 회원제 서비스 제공 및 본인 확인
  • 부정 이용 방지 및 비인가 사용 방지
  • 이용약관 위반 회원에 대한 제재 조치
  • 분쟁 조정을 위한 기록 보존
  • 고지사항 전달

【 서비스 제공 및 개선 】
  • 커뮤니티 기능 제공 (게시글/댓글 작성, 좋아요, 스크랩, 팔로우)
  • 급여 및 연금 계산 서비스 제공
  • 직렬별 라운지 접근 권한 관리
  • 반익명 시스템 운영 (닉네임 + 직렬 표시)
  • 서비스 이용 통계 분석 (Firebase Analytics)
  • 앱 성능 최적화 (Firebase Performance Monitoring)
  • 오류 및 장애 대응 (Crashlytics)
  • 맞춤형 콘텐츠 추천

【 공직자 메일 인증 】
  • 정부기관 재직 확인 (선택 기능)
  • 인증된 사용자 배지 표시
  • 특정 라운지 접근 권한 부여

【 마케팅 및 광고 】
  • 신규 서비스 및 이벤트 정보 안내 (푸시 알림, 동의 시에만)
  • 서비스 통계 분석
''',
            ),

            _buildSection(
              theme,
              title: '4. 개인정보의 보유 및 이용 기간',
              content: '''
【 원칙 】
회사는 이용자의 개인정보를 수집 및 이용 목적이 달성된 때에는 지체 없이 파기합니다. 단, 관계 법령에 따라 보존할 필요가 있는 경우 아래와 같이 일정 기간 보관합니다.

【 회원 탈퇴 시 】
  • 회원 정보: 즉시 삭제 (단, 아래 법령에 따른 보관 제외)
  • 작성한 게시글/댓글: 사용자 선택에 따라 삭제 또는 익명화 처리
  • 닉네임 이력: 30일간 보관 후 삭제 (재가입 시 닉네임 중복 방지)

【 법령에 따른 보관 】
  • 계약 또는 청약철회 등에 관한 기록: 5년 (전자상거래법)
  • 대금결제 및 재화 등의 공급에 관한 기록: 5년 (전자상거래법)
  • 소비자 불만 또는 분쟁처리 기록: 3년 (전자상거래법)
  • 표시/광고에 관한 기록: 6개월 (전자상거래법)
  • 접속 로그 기록: 3개월 (통신비밀보호법)
  • 서비스 이용 기록 (부정 이용 방지): 1년 (정보통신망법)

【 Firebase 서비스 보관 기간 】
  • Firebase Analytics: 최대 14개월 (Google 정책)
  • Crashlytics 로그: 최대 90일
  • Performance Monitoring: 최대 90일
''',
            ),

            _buildSection(
              theme,
              title: '5. 개인정보의 제3자 제공',
              content: '''
회사는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다.

다만, 다음의 경우 예외로 합니다:
  • 이용자가 사전에 동의한 경우
  • 법령의 규정에 의하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우
  • 통계 작성, 학술 연구 또는 시장조사를 위해 특정 개인을 식별할 수 없는 형태로 제공하는 경우

【 Firebase 서비스 이용에 따른 데이터 처리 】
회사는 서비스 운영을 위해 Google LLC의 Firebase 플랫폼을 이용합니다:
  • Firebase Authentication (계정 관리)
  • Cloud Firestore (데이터베이스)
  • Firebase Storage (이미지 저장)
  • Firebase Analytics (익명화된 통계)
  • Firebase Performance Monitoring (성능 측정)
  • Firebase Crashlytics (오류 로그)

Google의 개인정보 처리방침: https://policies.google.com/privacy
Firebase 데이터 처리 약관: https://firebase.google.com/terms/data-processing-terms

Firebase 서비스는 Google Cloud Platform의 보안 기준을 준수하며, 데이터는 암호화되어 저장됩니다.
''',
            ),

            _buildSection(
              theme,
              title: '6. 개인정보의 파기 절차 및 방법',
              content: '''
【 파기 절차 】
  • 이용자의 개인정보는 목적 달성 후 즉시 파기됩니다.
  • 법령에 따라 보관해야 하는 정보는 별도의 데이터베이스(DB)로 옮겨져 일정 기간 저장된 후 파기됩니다.

【 파기 방법 】
  • 전자적 파일: 복구 불가능한 방법으로 영구 삭제 (Firebase 문서 삭제, Storage 파일 삭제)
  • 종이 문서: 분쇄기로 분쇄하거나 소각

【 파기 시기 】
  • 회원 탈퇴 요청 시: 즉시 파기 (법령 보관 의무 제외)
  • 보유 기간 만료 시: 만료일로부터 5일 이내 파기
  • Firebase 자동 삭제 정책에 따른 로그 데이터 파기
''',
            ),

            _buildSection(
              theme,
              title: '7. 이용자 및 법정대리인의 권리',
              content: '''
이용자(만 14세 미만인 경우 법정대리인)는 언제든지 다음의 권리를 행사할 수 있습니다:

【 열람 요구권 】
  • 앱 내 '프로필' → '프로필 편집'에서 본인 정보 확인 가능

【 정정·삭제 요구권 】
  • 앱 내에서 닉네임, 자기소개 등 직접 수정 가능 (단, 닉네임은 30일 1회 제한)
  • 직렬, 직급 등 핵심 정보는 고객센터 문의 필요

【 처리 정지 요구권 】
  • 앱 내 '설정' → '알림 설정'에서 푸시 알림 비활성화 가능
  • 커뮤니티 이용 정지 요청 시 고객센터 문의

【 삭제 요구권 (회원 탈퇴) 】
  • 앱 내 '설정' → '계정 관리' → '회원 탈퇴'
  • 탈퇴 시 모든 개인정보는 즉시 파기 (법령 보관 의무 제외)
  • 작성한 게시글/댓글은 사용자 선택에 따라 삭제 또는 익명화 처리

【 만 14세 미만 아동의 개인정보 처리 】
회사는 만 14세 미만 아동의 개인정보를 수집하지 않습니다. 만 14세 미만 아동이 가입한 사실이 확인될 경우 즉시 계정을 삭제합니다.

【 권리 행사 방법 】
  • 앱 내 기능 이용
  • 고객센터 이메일: hanisoft2022@gmail.com
  • 처리 기한: 요청일로부터 10일 이내
''',
            ),

            _buildSection(
              theme,
              title: '8. 개인정보의 안전성 확보 조치',
              content: '''
회사는 이용자의 개인정보를 안전하게 관리하기 위해 다음과 같은 기술적·관리적 조치를 취하고 있습니다.

【 기술적 조치 】
  • 비밀번호 암호화 저장 (Firebase Authentication 기본 제공)
  • 데이터 전송 시 SSL/TLS 암호화 (HTTPS)
  • Firestore Security Rules를 통한 데이터 접근 제어
  • Firebase Storage 접근 권한 제한
  • 해킹 및 악성코드 방지 시스템 운영
  • 정기적인 보안 업데이트 및 취약점 점검

【 관리적 조치 】
  • 개인정보 접근 권한 최소화 (개발자 계정 제한)
  • 정기적인 임직원 보안 교육
  • 개인정보 처리 시스템 접근 기록 관리 및 점검
  • 문서 보안을 위한 잠금장치 사용

【 물리적 조치 】
  • 전산실, 자료보관실 등의 접근통제 (해당 시)
  • 개인정보가 포함된 서류, 보조저장매체 등의 잠금장치
''',
            ),

            _buildSection(
              theme,
              title: '9. 개인정보 자동 수집 장치의 설치·운영 및 거부',
              content: '''
【 Firebase Analytics 및 쿠키 사용 】
회사는 서비스 개선을 위해 Firebase Analytics를 사용하며, 이 과정에서 다음 정보가 자동으로 수집됩니다:
  • 화면 조회 기록
  • 앱 실행 시간 및 빈도
  • 기기 정보 (OS, 앱 버전)
  • 대략적인 위치 정보 (국가/지역 수준, GPS 아님)

【 수집 거부 방법 】
  • Android: 설정 → Google → 광고 → '광고 맞춤설정 선택 해제' 또는 '광고 ID 재설정'
  • iOS: 설정 → 개인정보 보호 → 추적 → 앱이 추적을 요청하도록 허용 '끄기'

단, Analytics를 완전히 거부하면 일부 맞춤형 서비스 제공이 제한될 수 있습니다.
''',
            ),

            _buildSection(
              theme,
              title: '10. 개인정보 보호책임자',
              content: '''
회사는 개인정보 처리에 관한 업무를 총괄하는 개인정보 보호책임자를 지정하고 있습니다.

【 개인정보 보호책임자 】
  • 소속: HANISOFT
  • 이메일: hanisoft2022@gmail.com
  • 응답 시간: 평일 09:00-18:00 (영업일 기준 3일 이내 회신)

【 개인정보 침해 신고 및 상담 】
개인정보 침해에 대한 신고나 상담이 필요하신 경우 아래 기관에 문의하실 수 있습니다:
  • 개인정보침해신고센터: privacy.kisa.or.kr (국번없이 118)
  • 개인정보분쟁조정위원회: kopico.go.kr (1833-6972)
  • 대검찰청 사이버수사과: cybercid.spo.go.kr (국번없이 1301)
  • 경찰청 사이버안전국: cyberbureau.police.go.kr (국번없이 182)
''',
            ),

            _buildSection(
              theme,
              title: '11. 개인정보 처리방침의 변경',
              content: '''
본 개인정보 처리방침은 법령, 정책 또는 보안기술의 변경에 따라 내용이 추가, 삭제 및 수정될 수 있으며, 변경 시 앱 내 공지사항 또는 이메일을 통해 고지합니다.

【 중요 변경 사항 발생 시 】
  • 변경 사항 시행일로부터 최소 7일 전 공지
  • 이용자에게 불리한 변경의 경우 30일 전 공지

【 개정 이력 】
  • 2025년 1월 8일: 최초 작성 및 시행
''',
            ),

            _buildSection(
              theme,
              title: '12. GDPR(유럽 개인정보 보호법) 준수',
              content: '''
회사는 유럽연합(EU) 거주자의 개인정보를 처리하는 경우, GDPR에 따라 다음 권리를 보장합니다:
  • 정보 접근권 (Right to Access)
  • 정정권 (Right to Rectification)
  • 삭제권 (Right to Erasure / Right to be Forgotten)
  • 처리 제한권 (Right to Restriction of Processing)
  • 데이터 이동권 (Right to Data Portability)
  • 반대권 (Right to Object)

EU 거주자는 위 권리 행사를 위해 hanisoft2022@gmail.com으로 요청하실 수 있습니다.
''',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '문의하기',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '개인정보 처리방침에 대한 문의사항이 있으시면 아래 이메일로 연락주시기 바랍니다.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이메일: hanisoft2022@gmail.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
