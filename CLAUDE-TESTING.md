# CLAUDE-TESTING.md

**Testing Strategy and Guidelines for GongMuTalk**

This document contains detailed testing strategies, coverage goals, and test patterns for AI agents working on this project.

📚 **Main Document**: [CLAUDE.md](CLAUDE.md)

---

## Testing Strategy

**Current Status** (As of 2025):
- **Test Files**: 3 files
  - `test/features/auth/data/auth_user_session_test.dart`
  - `test/features/community/data/services/interaction_cache_manager_test.dart` ✅ (모범 사례)
  - `test/models_roundtrip_test.dart`
- **Overall Coverage**: <2%
- **Status**: 🚧 Infrastructure ready, gradual expansion needed

---

## Tier-Based Approach

### 🔴 Tier 1 - Critical Path (반드시 테스트)

**금융 로직 수준의 정확도 필요**:

```bash
# 급여 계산 (최우선!)
test/features/calculator/domain/services/salary_calculation_service_test.dart

# 연금 계산
test/features/calculator/domain/services/pension_calculation_service_test.dart

# 인증 및 권한
test/features/auth/presentation/cubit/auth_cubit_test.dart
test/features/community/domain/services/lounge_access_service_test.dart

# 결제/포인트 (있다면)
test/features/*/payment_*_test.dart
```

**목표 커버리지**: **90%+**

**이유**:
- 급여/연금 계산 오류 → 사용자 신뢰 상실
- 인증 오류 → 보안 문제
- 금전적 영향이 직접적

**우선순위**:
1. Week 1-2: 급여 계산 테스트
2. Week 3-4: 연금 계산 테스트
3. Week 5-6: 인증 로직 테스트

---

### 🟡 Tier 2 - Core Business Logic (적극 테스트)

**데이터 무결성 및 비즈니스 로직**:

```bash
# Repositories
test/features/*/data/repositories/*_repository_test.dart

# Domain Services
test/features/*/domain/services/*_service_test.dart

# Cache Managers
test/features/*/data/services/*_cache_manager_test.dart
test/features/*/data/services/*_enrichment_service_test.dart
```

**목표 커버리지**:
- **Repositories**: 60%+
- **Services**: 70%+

**이유**:
- 데이터 일관성 보장
- 캐싱 로직 검증
- API 계약 준수

**테스트 패턴**:
```dart
// Repository 테스트
test('should return Right(data) when fetch succeeds', () async {
  when(() => dataSource.fetchPosts()).thenAnswer((_) async => [mockPost]);

  final result = await repository.fetchPosts();

  expect(result, Right([mockPost]));
  verify(() => dataSource.fetchPosts()).called(1);
});

test('should return Left(ServerFailure) when network fails', () async {
  when(() => dataSource.fetchPosts()).thenThrow(ServerException());

  final result = await repository.fetchPosts();

  expect(result, isA<Left<Failure, List<Post>>>());
});

// Service 테스트
test('should return cached data when cache is fresh', () {
  cacheManager.updateCache(uid: 'user1', likedIds: {'post1'});

  expect(cacheManager.shouldRefreshCache(), isFalse);
  expect(cacheManager.getCachedLikedIds('user1'), {'post1'});
});
```

---

### 🟢 Tier 3 - Presentation Layer (선택적)

**UI 상태 관리**:

```bash
# Cubits (complex state)
test/features/*/presentation/cubit/*_cubit_test.dart

# Widgets (complex only)
test/features/*/presentation/widgets/*_test.dart
```

**목표 커버리지**:
- **Cubits**: 40%+
- **Widgets**: 10-20% (복잡한 것만)

**이유**:
- UI는 빠르게 변하므로 테스트 유지비용 고려
- Cubit은 비즈니스 로직 포함 시 테스트
- Widget은 복잡한 조건부 렌더링만 테스트

**테스트 패턴**:
```dart
// Cubit 테스트 (bloc_test 사용)
blocTest<CommunityCubit, CommunityState>(
  'emits [loading, loaded] when fetchPosts succeeds',
  build: () => CommunityCubit(repository: mockRepository),
  act: (cubit) => cubit.fetchPosts(),
  expect: () => [
    CommunityState.loading(),
    CommunityState.loaded(posts: mockPosts),
  ],
  verify: (_) {
    verify(() => mockRepository.fetchPosts()).called(1);
  },
);

// Widget 테스트 (복잡한 것만)
testWidgets('should render error state when data fails', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubitWithError,
        child: MyComplexWidget(),
      ),
    ),
  );

  expect(find.text('Error occurred'), findsOneWidget);
  expect(find.byType(RetryButton), findsOneWidget);
});
```

---

## AI Testing Checklist

### When Creating a Repository

**Must Test**:
- ✅ Successful data fetch returns `Right(data)`
- ✅ Network error returns `Left(NetworkFailure())`
- ✅ Server error returns `Left(ServerFailure())`
- ✅ Data source called with correct parameters
- ✅ Error handling for each external call

**Example**:
```dart
test('should return Right(posts) when fetch succeeds', () async {
  when(() => dataSource.fetchPosts()).thenAnswer((_) async => [mockPost]);

  final result = await repository.fetchPosts();

  expect(result, Right([mockPost]));
  verify(() => dataSource.fetchPosts()).called(1);
});

test('should return Left(ServerFailure) when data source throws', () async {
  when(() => dataSource.fetchPosts()).thenThrow(ServerException());

  final result = await repository.fetchPosts();

  expect(result, Left(ServerFailure()));
});
```

### When Creating a Service (CacheManager, EnrichmentService, etc.)

**Must Test**:
- ✅ Cache hit returns cached data without external calls
- ✅ Cache miss triggers data fetch
- ✅ TTL expiration triggers refresh
- ✅ Cache statistics tracking (if applicable)
- ✅ Service coordinates multiple repositories correctly

**Example**:
```dart
test('should return cached data when cache is fresh', () {
  cacheManager.updateCache(uid: 'user1', likedIds: {'post1'});

  expect(cacheManager.shouldRefreshCache(), isFalse);
  expect(cacheManager.getLikedPostIds('user1'), {'post1'});
});

test('should refresh cache after TTL expiration', () async {
  cacheManager.updateCache(uid: 'user1', likedIds: {'post1'});

  // Simulate time passage (mock DateTime or use fake_async)
  await Future.delayed(Duration(minutes: 11));

  expect(cacheManager.shouldRefreshCache(), isTrue);
});
```

### When Creating a Cubit

**Must Test**:
- ✅ Initial state is correct
- ✅ State transitions for success case
- ✅ State transitions for error case
- ✅ State transitions for loading case
- ✅ Repository called with correct parameters

**Example** (using bloc_test):
```dart
blocTest<CommunityCubit, CommunityState>(
  'emits [loading, loaded] when fetchPosts succeeds',
  build: () {
    when(() => repository.fetchPosts()).thenAnswer(
      (_) async => Right([mockPost]),
    );
    return CommunityCubit(repository);
  },
  act: (cubit) => cubit.fetchPosts(),
  expect: () => [
    CommunityState.loading(),
    CommunityState.loaded(posts: [mockPost]),
  ],
  verify: (_) {
    verify(() => repository.fetchPosts()).called(1);
  },
);

blocTest<CommunityCubit, CommunityState>(
  'emits [loading, error] when fetchPosts fails',
  build: () {
    when(() => repository.fetchPosts()).thenAnswer(
      (_) async => Left(ServerFailure()),
    );
    return CommunityCubit(repository);
  },
  act: (cubit) => cubit.fetchPosts(),
  expect: () => [
    CommunityState.loading(),
    CommunityState.error(message: 'Server error'),
  ],
);
```

### When Creating a Widget

**Test if**:
- Widget is complex (400+ lines)
- Widget has conditional rendering logic
- Widget handles user interactions
- Widget is reused in multiple places

**Must Test** (if testing):
- ✅ Widget renders without errors
- ✅ Conditional branches render correctly
- ✅ User interactions trigger expected callbacks
- ✅ Edge cases (null data, empty lists, errors)

**Example**:
```dart
testWidgets('should display post content', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PostCard(post: mockPost),
    ),
  );

  expect(find.text(mockPost.title), findsOneWidget);
  expect(find.text(mockPost.content), findsOneWidget);
});

testWidgets('should call onLike when like button tapped', (tester) async {
  var likeCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: PostCard(
        post: mockPost,
        onLike: () => likeCalled = true,
      ),
    ),
  );

  await tester.tap(find.byIcon(Icons.favorite_border));
  expect(likeCalled, isTrue);
});
```

---

## Overall Project Coverage Goals

**현실적 Timeline**:

| Phase | Duration | Target | Focus |
|-------|----------|--------|-------|
| Phase 1 | Week 1-4 | Overall ~8% | Tier 1 급여/연금 90%+ |
| Phase 2 | Month 2-3 | Overall ~20% | Tier 2 Repositories 60%+ |
| Phase 3 | Month 4-6 | Overall ~30% | Tier 2 Services 70%+ |
| Phase 4 | Month 7-12 | Overall ~50% | Tier 3 Cubits 40%+ |

**이유**:
- 현재 <2%에서 40%는 비현실적
- Tier 1 집중이 사용자에게 가장 중요
- 점진적 증가가 지속 가능

**Milestone 체크포인트**:
- ✅ Month 1: 급여 계산 90%+ → "신뢰할 수 있는 계산기"
- ✅ Month 3: Repository 60%+ → "데이터 무결성 보장"
- ✅ Month 6: Overall 30%+ → "업계 스타트업 평균 도달"
- ✅ Year 1: Overall 50%+ → "견고한 프로젝트"

---

## Coverage != Quality

**중요한 원칙**:

```
✅ 80%의 의미 있는 테스트 >> 100%의 형식적 테스트

// ❌ Bad: 형식적 테스트
test('model has correct fields', () {
  expect(post.id, isNotNull); // 의미 없음
});

// ✅ Good: 의미 있는 테스트
test('should calculate net salary correctly with grade 15', () {
  final salary = service.calculateNetSalary(
    grade: 15,
    allowances: Allowance(family: 100000),
  );

  expect(salary.gross, 3500000); // 실제 계산 검증
  expect(salary.tax, 350000);
  expect(salary.net, 3150000);
});
```

**테스트하지 않아도 되는 것**:
- Generated code (없지만)
- 단순 getter/setter
- 프레임워크 코드 (Flutter/Firebase)
- 단순 UI 애니메이션

**반드시 테스트해야 하는 것**:
- 급여/연금 계산 로직
- 인증 및 권한 로직
- 데이터 변환 로직
- 에러 처리 로직
- 캐싱 로직

---

## Mocking Strategy

**Use mocktail for dependencies**:

```dart
// Mock repositories
class MockCommunityRepository extends Mock implements CommunityRepository {}
class MockAuthCubit extends MockBloc<AuthState> implements AuthCubit {}

// DON'T mock
// ❌ Entities (Post, Comment, User)
// ❌ Value objects (CareerTrack, Allowance)
// ❌ Simple data models
```

---

## Measuring Success

**Coverage 명령어**:
```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

**CI/CD Integration**:
```yaml
# .github/workflows/test.yml
- name: Run tests
  run: flutter test --coverage

- name: Check Tier 1 coverage
  run: |
    # Tier 1 (급여/연금) must be 90%+
    # Fail build if below threshold
```

**Coverage Badges** (optional):
```markdown
[![Coverage](https://img.shields.io/badge/coverage-15%25-yellow.svg)]()
[![Tier 1](https://img.shields.io/badge/tier%201-90%25-brightgreen.svg)]()
```

---

## Linting & Code Quality

- **Base**: flutter_lints (in analysis_options.yaml)
- **Enhanced**: very_good_analysis (available in dev dependencies)
- **Custom rules**: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`
- **Excluded**: `lib/generated_plugin_registrant.dart`

**Commands**:
```bash
flutter analyze
dart format lib test
flutter test --coverage
```

---

## Error Tracking

- **Production**: Sentry Flutter (crash reporting, error monitoring)
- **Development**: Firebase Crashlytics

---

## Coverage Requirements Summary

When implementing new features, ensure:

- ✅ **Domain layer**: 80%+ coverage (entities, usecases)
- ✅ **Services**: 70%+ coverage (cache managers, enrichment services)
- ✅ **Repositories**: 60%+ coverage (data layer)
- ✅ **Cubits**: 50%+ coverage (state management)
- ⚠️ **Widgets**: Test complex widgets only (optional, <50% is acceptable)

**Before submitting PR**:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # Check coverage report
```

Ensure new code meets minimum 50% coverage before merge.

---

## When to Reference This Document

**AI agents should read CLAUDE-TESTING.md when**:
- Writing tests for new features
- Determining testing priority (Tier 1/2/3)
- Questions about coverage goals
- Looking for test pattern examples
- Setting up CI/CD for testing

**Don't need to read if**:
- Architectural pattern questions (see CLAUDE-PATTERNS.md)
- Domain knowledge questions (see CLAUDE-DOMAIN.md)
- Quick start or setup questions (see CLAUDE.md)
