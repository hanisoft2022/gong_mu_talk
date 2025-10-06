# PostCard Cubit Implementation Summary

## 📊 프로젝트 상태 (2025-01-06)

### ✅ 완료된 작업 (Phase 1)

#### 1. PostCardCubit + PostCardState 구현
**파일**:
- `lib/features/community/presentation/cubit/post_card_cubit.dart` (217 lines)
- `lib/features/community/presentation/cubit/post_card_state.dart` (73 lines)

**기능**:
- ✅ 댓글 로딩 (featured + timeline, 베스트 댓글 로직 포함)
- ✅ 댓글 제출 (이미지 URL 지원)
- ✅ 댓글 좋아요 토글 (Optimistic Update 패턴)
- ✅ 게시글 신고
- ✅ 사용자 차단
- ✅ 조회수 추적 (1회만)
- ✅ 에러 상태 관리

**아키텍처 원칙 준수**:
- ✅ CLAUDE.md 원칙: "Repository 호출 → Cubit 필수" 100% 준수
- ✅ Clean Architecture: Domain/Data/Presentation 계층 분리
- ✅ 비즈니스 로직과 UI 완전 분리

---

#### 2. 테스트 작성 (TDD 방식)
**파일**:
- `test/features/community/presentation/cubit/post_card_cubit_test.dart` (441 lines)

**커버리지**:
- ✅ **20개 테스트 모두 통과** 🎉
- ✅ **Tier 2-3 수준 달성** (CLAUDE-TESTING.md 기준)

**테스트 카테고리**:
1. Initial State (3 tests)
2. loadComments (6 tests)
   - 성공 케이스
   - Featured 댓글 조건 검증 (2가지)
   - 에러 핸들링
   - Force reload
3. submitComment (4 tests)
   - 성공 케이스
   - 빈 댓글 검증 (2가지)
   - 에러 핸들링
4. toggleCommentLike (2 tests)
   - Optimistic update
   - 실패 시 rollback
5. reportPost (2 tests)
6. blockUser (2 tests)
7. trackView (1 test)
8. clearError (1 test)

**테스트 품질**:
- ✅ Mock repository 사용 (mocktail)
- ✅ BlocTest 활용
- ✅ State transition 검증
- ✅ Repository call 횟수 검증

---

#### 3. E2E 테스트 가이드 작성
**파일**:
- `POST_CARD_REFACTORING_E2E_TEST_GUIDE.md`

**내용**:
- 12개 수동 테스트 케이스
- Before/After 비교 매트릭스
- 실패 시나리오 정의
- Sign-off 체크리스트

---

### 📋 Phase 2: PostCard 리팩토링 (다음 단계)

**목표**: Repository 직접 호출 → PostCardCubit 호출 전환

**변경 범위**:
```dart
// ❌ Before (현재 - 978 lines)
class _PostCardState extends State<PostCard> {
  late final CommunityRepository _repository;
  
  Future<void> _loadComments() async {
    await _repository.getComments(widget.post.id); // 직접 호출
    setState(() { ... }); // 로컬 상태 관리
  }
}

// ✅ After (목표)
class PostCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostCardCubit(
        repository: context.read<CommunityRepository>(),
        postId: post.id,
        initialCommentCount: post.commentCount,
      ),
      child: _PostCardContent(post: post),
    );
  }
}

class _PostCardContent extends StatefulWidget { // UI 애니메이션만 유지
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCardCubit, PostCardState>(
      builder: (context, state) {
        // Cubit state 사용
      },
    );
  }
}
```

**예상 변경 사항**:
1. **BlocProvider 추가**: PostCard를 BlocProvider로 래핑
2. **Repository 제거**: `_repository` 필드 삭제 (7개 호출 모두 제거)
3. **State 마이그레이션**:
   - `_isLoadingComments` → `state.isLoadingComments`
   - `_featuredComments` → `state.featuredComments`
   - `_timelineComments` → `state.timelineComments`
   - `_commentCount` → `state.commentCount`
   - `_isSubmittingComment` → `state.isSubmittingComment`
4. **setState → emit**: 19개 setState 호출 제거
5. **BlocBuilder/BlocListener 추가**: UI rebuild 최적화

**파일 크기 예상**:
- Before: 978 lines
- After: ~700 lines (setState 제거, BlocBuilder로 단순화)

---

### 🎯 예상 효과

#### 아키텍처 개선
- ✅ CLAUDE.md 원칙 100% 준수
- ✅ Repository → Cubit → UI 명확한 계층
- ✅ 비즈니스 로직 재사용 가능 (PostCardCubit 독립적)

#### 테스트 가능성
- ✅ Cubit 단위 테스트 **이미 완료** (20개)
- ✅ Widget 테스트 분리 가능
- ✅ Mock repository 주입 용이

#### 유지보수성
- ✅ 상태 관리 명시적 (디버깅 쉬움)
- ✅ 코드 중복 감소
- ✅ 회귀 버그 방지 (테스트 커버리지)

---

### ⚠️ 리팩토링 시 주의사항

1. **UI 애니메이션 유지**
   - `_isExpandedNotifier`, `_showCommentsNotifier` → ValueNotifier 유지
   - TickerProviderStateMixin → StatefulWidget 유지 (animation용)
   
2. **이미지 업로드**
   - 현재: PostCard StatefulWidget에서 관리
   - 다음 단계: 별도 ImageUploadCubit로 분리 (Phase 3)
   
3. **Menu Overlay**
   - `_menuOverlayEntry` → StatefulWidget에서 관리 유지
   - Pure UI 로직이므로 Cubit 불필요

4. **Synthetic Post 처리**
   - `_isSynthetic()` 로직 유지
   - Preview 게시물 특별 처리

---

### 📈 진행률

**Phase 1: Infrastructure (완료)**
- [x] PostCardCubit + State 구현
- [x] 20개 테스트 작성 및 통과
- [x] E2E 테스트 가이드 작성

**Phase 2: PostCard 리팩토링 (다음)**
- [ ] BlocProvider 추가
- [ ] Repository 호출 → Cubit 호출
- [ ] setState → BlocBuilder/BlocListener
- [ ] E2E 테스트 실행 및 검증

**Phase 3: 추가 개선 (선택)**
- [ ] ImageUploadCubit 분리
- [ ] Widget 테스트 추가
- [ ] Repository/Service 테스트 확장 (현재 1개 → 목표 5개)

---

## 🚀 다음 작업 순서 (권장)

### 즉시 실행 가능
1. **PostCard 리팩토링 시작**
   ```bash
   # 1. BlocProvider 추가
   # 2. _loadComments() 메서드 제거 → cubit.loadComments() 호출
   # 3. Build에서 BlocBuilder 사용
   ```

2. **E2E 테스트 실행**
   ```bash
   flutter run
   # POST_CARD_REFACTORING_E2E_TEST_GUIDE.md 따라 수동 테스트
   ```

3. **커버리지 확인**
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```

### 단계별 체크리스트

**Step 1: BlocProvider 래핑**
- [ ] PostCard → BlocProvider(create: ..., child: _PostCardContent)
- [ ] BlocProvider에서 PostCardCubit 생성
- [ ] repository, postId, initialCommentCount 전달

**Step 2: 댓글 로딩 변경**
- [ ] `_loadComments()` 메서드 제거
- [ ] `_handleCommentButton()` → `context.read<PostCardCubit>().loadComments()`
- [ ] `_isLoadingComments` → `state.isLoadingComments` (BlocBuilder)
- [ ] `_featuredComments` → `state.featuredComments`
- [ ] `_timelineComments` → `state.timelineComments`

**Step 3: 댓글 제출 변경**
- [ ] `_submitComment()` 메서드 제거
- [ ] Submit button → `cubit.submitComment(text, imageUrls: ...)`
- [ ] `_isSubmittingComment` → `state.isSubmittingComment`
- [ ] `_commentCount` → `state.commentCount`

**Step 4: 댓글 좋아요 변경**
- [ ] `_handleCommentLike()` 메서드 제거
- [ ] Like button → `cubit.toggleCommentLike(comment)`
- [ ] Optimistic update 로직 제거 (Cubit에서 처리)

**Step 5: Report/Block 변경**
- [ ] `_handleReport()` → `cubit.reportPost(reason)`
- [ ] `_handleBlockUser()` → `cubit.blockUser(uid)`

**Step 6: View Tracking 변경**
- [ ] `_registerInteraction()` → `cubit.trackView()`
- [ ] `_hasTrackedInteraction` → `state.hasTrackedView`

**Step 7: Error Handling**
- [ ] BlocListener로 error state 감지
- [ ] SnackBar 표시
- [ ] `cubit.clearError()` 호출

**Step 8: E2E 테스트**
- [ ] 12개 테스트 케이스 모두 실행
- [ ] 실패 케이스 디버깅
- [ ] Sign-off

---

## 📝 파일 변경 요약

### 새로 생성된 파일
- ✅ `lib/features/community/presentation/cubit/post_card_cubit.dart`
- ✅ `lib/features/community/presentation/cubit/post_card_state.dart`
- ✅ `test/features/community/presentation/cubit/post_card_cubit_test.dart`
- ✅ `POST_CARD_REFACTORING_E2E_TEST_GUIDE.md`
- ✅ `POST_CARD_CUBIT_IMPLEMENTATION_SUMMARY.md` (이 파일)

### 변경 예정 파일
- ⏳ `lib/features/community/presentation/widgets/post_card.dart` (대규모 변경)

### 변경 불필요 파일
- ✅ `lib/di/di.dart` (PostCardCubit은 위젯에서 직접 생성)
- ✅ 모든 child widgets (post/\*.dart) - 변경 없음

---

## 🎓 학습 포인트

### TDD 방식의 이점
1. **테스트 먼저** → 요구사항 명확화
2. **구현 후** → 테스트가 즉시 검증
3. **리팩토링 안전** → 회귀 방지

### BLoC 패턴의 이점
1. **명시적 상태 관리** → 디버깅 용이
2. **테스트 가능성** → Mock 주입 쉬움
3. **재사용성** → Cubit 독립적

### CLAUDE.md 원칙 준수
1. **Repository 호출 → Cubit 필수** ✅
2. **단일 책임 > 파일 크기** ✅
3. **테스트 의미 > 커버리지 숫자** ✅

---

**Last Updated**: 2025-01-06  
**Author**: Claude Code  
**Status**: Phase 1 Complete, Phase 2 Ready
