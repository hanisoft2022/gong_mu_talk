# 공무톡 (GongMuTalk)

공무원 커뮤니티 앱을 위한 Flutter + Firebase 구현입니다. 익명 기반 쫑알쫑알 피드, 게시판형 커뮤니티, 검색/추천, 신고·모더레이션, 포인트/뱃지 등 핵심 기능을 포함합니다.

## 주요 기능

- **닉네임/프로필**: `users` + `handles` 컬렉션으로 닉네임 고유성 보장, 트랜잭션 기반 변경, 직렬·부서·지역 필터 설정.
- **쫑알쫑알 피드**: 전체/직렬/인기 탭, 카드형 5줄 미리보기 + 최다 좋아요 댓글 프리뷰, 카드 외부 좋아요 토글, Firebase Storage 이미지 업로드/썸네일 지원.
- **게시판 커뮤니티**: 게시판 목록/피드, 실명 필수 게시판 토글, 북마크, 오늘의 베스트(핫스코어 기반).
- **검색/자동완성**: prefix 토큰화 + `search_suggestions` 집계, 인기/자동완성 추천, 결과 리스트에서 좋아요/스크랩/뷰 카운트 연동.
- **카운터 & 랭킹**: 핫스코어(`3*likes + 5*comments + 1*views – decay`) 계산, 셰어드 카운터 샤드 구조, Cloud Functions 트리거(`onLikeWrite`, `onCommentWrite`, `onPostWrite`).
- **모더레이션**: 신고 컬렉션, 게시글 숨김, 금칙어/PII 필터링 훅, 제재 단계 데이터 모델.
- **보안**: Firestore/Storage 규칙, App Check 토큰 검사, 문서 오너/카운터 업데이트 분리 검증.

## Flutter 구조 개요

```
lib/
 ├─ features/
 │   ├─ community/    # 피드, 게시판, 검색, 신고 등
 │   ├─ profile/      # 프로필/닉네임/포인트
 │   ├─ auth/         # 인증, AppShell 연동
 │   └─ ...
 ├─ core/             # 공통 유틸 (핫스코어, prefix tokenizer 등)
 ├─ di/               # GetIt DI 구성
 ├─ routing/          # GoRouter 라우트 정의 (Community/Boards/Search/Compose 포함)
 └─ main.dart
```

- 상태 관리는 `flutter_bloc` 기반 Cubit 구조.
- `CommunityRepository`가 Firestore/Storage CRUD 및 prefix 토큰, 검색, 신고 등을 담당.
- `CommunitySearchCubit`은 자동완성/검색 결과/좋아요/북마크 상태를 관리하며 `CommunitySearchPage`에서 UI 제공.
- `BoardFeedCubit`/`CommunityFeedCubit`은 무한 스크롤, 낙관적 좋아요/스크랩 토글, 조회수 증가를 처리.
- Cloud Functions(`functions/src/index.ts`)가 카운터/핫스코어/검색 토큰/최고 댓글 캐시를 서버 측에서 유지.

## Firebase Cloud Functions

- `onLikeWrite`: 좋아요 생성/삭제 시 `posts.likeCount`, 셰어드 카운터 샤드, 핫스코어 재계산.
- `onCommentWrite`: 댓글 작성/삭제/좋아요 변화 시 `commentCount`, 핫스코어, `topComment` 캐시 갱신.
- `onPostWrite`: 태그/키워드 정규화 및 prefix 토큰 차이 기반 `search_suggestions` 카운트 조정.
- Dart의 `HotScoreCalculator`/`PrefixTokenizer` 로직과 동일하게 TypeScript로 구현되었습니다. (TODO: 가중치 Remote Config 연동)

## Firestore / Storage 보안 규칙 요약

- 인증 + App Check 토큰 필수.
- 게시글 작성자는 본문/태그/미디어 등만 수정 가능, 카운터 필드는 카운터 전용 업데이트 경로로 제한.
- 댓글 작성/삭제, 좋아요 토글, 북마크, 신고 등은 작성자 및 본인 문서 접근만 허용.
- Storage는 `/post_images/{uid}/...`, `/profile_images/{uid}/...` 경로에 대해 소유자 + App Check + 이미지 MIME/10MB 제한.

## 콘솔 작업 체크리스트

- [ ] **Authentication**: 이메일(또는 기타) 로그인 활성화, App Check 등록 및 강제 적용.
- [ ] **Firestore 인덱스** 생성:
  1. `posts`: `type` ASC + `visibility` ASC + `createdAt` DESC
  2. `posts`: `type` ASC + `audience` ASC + `serial` ASC + `visibility` ASC + `createdAt` DESC
  3. `posts`: `type` ASC + `boardId` ASC + `visibility` ASC + `createdAt` DESC
  4. `posts`: `type` ASC + `visibility` ASC + `hotScore` DESC
  5. `posts`: `visibility` ASC + `keywords` array-contains + `hotScore` DESC
  6. (선택) `posts`: `tags` array-contains + `createdAt` DESC
  7. `comments` 컬렉션 그룹: `deleted` ASC + `likeCount` DESC + `createdAt` ASC
- [ ] **Storage**: 규칙 배포, 이미지 MIME( jpeg/png/gif/webp ) 및 10MB 용량 제한 확인.
- [ ] **Cloud Functions**: `onLikeWrite`, `onCommentWrite`, `onPostWrite` 빌드/배포.
- [ ] **Firebase Extensions (선택)**: 이미지 썸네일 자동 생성, 검색 서비스(예: Algolia) 연동 검토.

## 개발/빌드 참고

- `flutter pub get` 후 `flutter run` 또는 `flutter build` 수행.
- Functions: `npm install && npm run build` 후 `firebase deploy --only functions`.
- 분석/로그: `lib/core/analytics` 영역에서 `post_view`, `post_like`, `comment_create`, `search_query`, `search_select` 이벤트 기록(TODO 주석 참고).

