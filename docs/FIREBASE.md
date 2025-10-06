# Firebase 설정 및 서비스 현황

## 📊 현재 사용 중인 Firebase 서비스

### ✅ 활성 서비스

#### 1. **Firestore Database**
- **용도**: 메인 데이터베이스
- **주요 컬렉션**:
  - `users/`: 사용자 프로필 및 서브컬렉션 (notifications, verifications, scraps, followers, following, etc.)
  - `posts/`: 게시글 및 댓글 (comments subcollection)
  - `likes/`: 좋아요 데이터
  - `post_counters/shards/`: 분산 카운터
  - `lounges/`: 라운지 정보
  - `government_email_*`: 공무원 이메일 인증
  - `handles/`: 사용자 핸들 (닉네임) 중복 방지
  - `reports/`: 신고 데이터
- **Location**: asia-northeast3 (서울)
- **Rules**: `firestore.rules`
- **Indexes**: `firestore.indexes.json`

#### 2. **Firebase Authentication**
- **용도**: 사용자 인증
- **인증 방법**: Email/Password (추후 소셜 로그인 추가 가능)

#### 3. **Firebase Storage**
- **용도**: 파일 저장
- **주요 경로**:
  - `paystub_uploads/{userId}/{fileName}`: 급여명세서 (Admin SDK만 읽기)
  - `profile_images/{userId}/{fileName}`: 프로필 이미지
  - `post_images/{userId}/{postId}/{fileName}`: 게시글 이미지
  - `comments/{year}/{month}/{postId}/{fileName}`: 댓글 이미지
- **Rules**: `storage.rules`

#### 4. **Firebase Functions**
- **용도**: 서버리스 백엔드 로직
- **활성 Functions**:
  - `handlePaystubUpload`: 급여명세서 OCR 및 직렬 감지
  - `sendGovernmentEmailVerification`: 공무원 이메일 인증 메일 발송
  - `verifyEmailToken`: 이메일 인증 토큰 검증
  - `onLikeWrite`: 좋아요 추가/삭제 시 카운터 업데이트
  - `onCommentWrite`: 댓글 추가/삭제 시 카운터 및 topComment 업데이트
  - `recalculateHotScores`: Hot score 주기적 재계산 (12시간마다)
  - `processReports`: 신고 처리 및 자동 모더레이션
- **Runtime**: Node.js 22, TypeScript
- **Region**: us-central1

#### 5. **Firebase Crashlytics**
- **용도**: 앱 크래시 모니터링 및 리포팅
- **통합**: iOS/Android 모두 활성화

#### 6. **Firebase Cloud Messaging (FCM)**
- **용도**: 푸시 알림
- **현재 상태**: ✅ **구현 완료** (`lib/core/services/notification_service.dart`)
  - FCM 토큰 관리
  - Topic 구독 기능
  - Foreground/Background 메시지 처리
  - Local notifications 통합
- **설정 필요**:
  - Firebase Console → Cloud Messaging → Cloud Messaging API 활성화 확인
  - APNs 인증 키 등록 (iOS)
  - 테스트 메시지 발송으로 동작 확인

---

## 🔧 Firebase Messaging 설정 가이드

### 1. Cloud Messaging API 활성화

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 → `Cloud Messaging` 메뉴
3. `Cloud Messaging API` 활성화 확인
4. Server Key 확인 (Functions에서 메시지 발송 시 필요)

### 2. iOS APNs 설정 (필수)

1. Apple Developer Center에서 APNs 인증 키 생성
2. Firebase Console → 프로젝트 설정 → Cloud Messaging → iOS 앱 설정
3. APNs 인증 키 업로드 (Key ID, Team ID 입력)
4. `ios/Runner/GoogleService-Info.plist` 최신 버전 확인

### 3. Android 설정 (자동 완료)

- `android/app/google-services.json` 파일로 자동 설정됨
- FCM SDK가 `pubspec.yaml`에 포함되어 있음 (`firebase_messaging`)

### 4. 테스트 방법

```bash
# 1. FCM 토큰 확인 (앱 실행 후 로그 확인)
flutter run

# 2. Firebase Console에서 테스트 메시지 발송
# Cloud Messaging → Send your first message → 디바이스 FCM 토큰 입력

# 3. 코드에서 토큰 출력 (디버그용)
# lib/core/services/notification_service.dart의 getToken() 호출
```

---

## 📈 권장 Firebase 서비스 (미사용 중)

### 🟢 높은 우선순위 (즉시 도입 권장)

#### 1. **Firebase Analytics**
- **이유**: 무료, 사용자 행동 분석 필수
- **활용 사례**:
  - 게시글 조회/작성 빈도 추적
  - Calculator 기능 사용률 분석
  - 라운지별 활성도 측정
  - User retention 분석
- **도입 방법**:
  ```yaml
  # pubspec.yaml
  dependencies:
    firebase_analytics: ^11.3.4
  ```

#### 2. **Firebase Performance Monitoring**
- **이유**: 무료, 앱 성능 병목 지점 파악
- **활용 사례**:
  - Firestore 쿼리 성능 모니터링
  - 이미지 로딩 시간 추적
  - Calculator 계산 속도 측정
- **도입 방법**:
  ```yaml
  # pubspec.yaml
  dependencies:
    firebase_performance: ^0.10.0+8
  ```

### 🟡 중간 우선순위 (필요 시 도입)

#### 3. **Firebase Remote Config**
- **이유**: 앱 재배포 없이 설정 변경 가능
- **활용 사례**:
  - 급여/연금 계산 공식 파라미터 조정
  - Feature flag (새 기능 점진적 배포)
  - A/B 테스팅 (UI 변경 실험)
  - 긴급 공지사항 표시
- **도입 방법**:
  ```yaml
  # pubspec.yaml
  dependencies:
    firebase_remote_config: ^5.1.4
  ```

#### 4. **Firebase App Distribution**
- **이유**: 베타 테스터에게 앱 배포 간소화
- **활용 사례**:
  - 내부 테스터 그룹에 빌드 배포
  - 릴리스 전 QA 테스팅
  - 크래시 피드백 수집

### 🔵 낮은 우선순위 (선택적)

#### 5. **Firebase Dynamic Links**
- **이유**: 딥링크, 웹-앱 연동 (웹 버전 출시 시 필요)
- **활용 사례**:
  - 게시글 공유 링크 (웹/앱 자동 전환)
  - 초대 링크
- **주의**: 2025년 8월 25일 지원 종료 예정 → **대안**: [App Links (Android)](https://developer.android.com/training/app-links) / [Universal Links (iOS)](https://developer.apple.com/ios/universal-links/)

---

## 🗑️ 정리 완료 (2025-10-06)

### 제거된 Firestore Rules
- `follows/` collection (마이그레이션 완료, subcollection으로 이전)
- `matches/` collection (미사용)
- `matching_likes/`, `matching_inbox/`, `matching_meta/` subcollections (미사용)

### 제거된 Firebase Functions
- `migrateMyData`, `migrateAllUsers` (일회성 마이그레이션 완료)
- `migrateFollowsData`, `cleanupOldFollowsCollection` (일회성 마이그레이션 완료)

---

## 🚀 배포 가이드

### Firestore Rules 배포
```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes 배포
```bash
firebase deploy --only firestore:indexes
```

### Storage Rules 배포
```bash
firebase deploy --only storage
```

### Functions 배포
```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

### 전체 배포
```bash
firebase deploy
```

---

## 📝 참고사항

### Firestore 비용 최적화
- **Caching 필수**: `lib/features/community/data/services/`의 CacheManager 활용
- **Pagination 필수**: 모든 쿼리에 `.limit()` 적용
- **whereIn 최적화**: 최대 30개 항목까지만 (Firestore 제한)
- **Listener 관리**: 불필요한 실시간 리스너는 `cancel()` 호출

### Functions 비용 최적화
- **Cold start 최소화**: 자주 호출되는 함수는 항상 warm 상태 유지
- **Timeout 설정**: 불필요하게 긴 timeout 방지
- **Region 선택**: asia-northeast1 (도쿄) 또는 us-central1 사용

### Storage 비용 최적화
- **이미지 압축**: `ImageCompressionUtil` 활용 (구현 완료)
- **Thumbnail 생성**: post_images에는 thumbnail 자동 생성
- **CDN 캐싱**: `cached_network_image` 패키지 활용

---

## 🔗 관련 문서
- [CLAUDE.md](CLAUDE.md): 프로젝트 전체 가이드
- [CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md): 아키텍처 패턴
- [CLAUDE-DOMAIN.md](CLAUDE-DOMAIN.md): 도메인 지식
- [CLAUDE-TESTING.md](CLAUDE-TESTING.md): 테스팅 전략
