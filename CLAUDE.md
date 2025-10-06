# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview & Vision

### What is GongMuTalk?

GongMuTalk (공무톡) is a Flutter-based comprehensive asset management and community platform for public servants in Korea. The app provides salary/pension calculators, community features, professional matching, and life management tools.

### Why GongMuTalk?

- **Complex Salary Calculations**: Korean public servant compensation involves intricate grade systems, allowances, and tax calculations
- **Information Asymmetry**: Career-specific information is scattered and hard to access
- **Community Need**: Public servants need a trusted space to share career insights and experiences
- **Career Management Gap**: Lack of integrated tools for salary planning, pension estimation, and career progression

### Core Value Proposition

1. **Accurate Financial Planning**: Precise salary and pension calculators based on official government data
2. **Career Track Verification**: OCR-based paystub verification for authentic community access
3. **Hierarchical Lounges**: Career-specific communities (e.g., elementary teachers, firefighters, tax officials)
4. **Privacy-First**: Semi-anonymous system protecting user identity while maintaining accountability

## How to Use This Document

### Purpose of This Document

This is a **living guideline**, not a rigid rulebook:
- ✅ Provides **principles** for consistent decision-making
- ✅ Captures **recurring patterns** and trade-offs
- ❌ Does NOT cover every edge case
- ❌ Does NOT require updates for minor variations

### How to Read This Document

**"Principles > Patterns > Examples > Numbers"**

When guidance conflicts, follow this hierarchy:
1. **Non-Negotiable Principles** (e.g., "No Code Generation")
2. **Core Project Principles** (e.g., "Single Responsibility > File Size")
3. **Recurring Patterns** (e.g., "Cubit for Repository calls")
4. **Guideline Numbers** (e.g., "400 lines") - References, not rules

**For AI Agents**:
- Don't ask to change Non-Negotiable Principles
- Use Core Principles to resolve ambiguous cases
- Numbers are guides - focus on the principle behind them

---

### 🚫 Non-Negotiable Principles

**These are permanent project decisions** - AI should NEVER suggest alternatives:

#### 1. Clean Architecture (Domain/Data/Presentation)
- ✅ Repository interfaces in domain layer
- ✅ Implementations in data layer
- ✅ Clear separation of concerns
- ❌ NO mixing layers
- ❌ NO direct Firebase calls from presentation

```dart
// ✅ Good: Clean separation
// domain/repositories/post_repository.dart
abstract class PostRepository {
  Future<Either<Failure, List<Post>>> fetchPosts();
}

// data/repositories/post_repository_impl.dart
class PostRepositoryImpl implements PostRepository {
  final PostDataSource _dataSource;
  // Implementation
}

// ❌ Bad: Direct Firebase in presentation
class PostCard extends StatelessWidget {
  Widget build(context) {
    FirebaseFirestore.instance.collection('posts').get(); // NO!
  }
}
```

#### 2. BLoC/Cubit for State Management
- ✅ BLoC/Cubit only for all state management
- ✅ flutter_bloc, bloc_concurrency
- ❌ NO Riverpod
- ❌ NO Provider
- ❌ NO GetX, Redux, MobX

```dart
// ✅ Good: Use Cubit
class CommunityCubit extends Cubit<CommunityState> {
  Future<void> fetchPosts() async { }
}

// ❌ Bad: Don't suggest alternatives
final postsProvider = StateNotifierProvider(...); // NO Riverpod!
```

#### 3. GetIt for Manual Dependency Injection
- ✅ Manual registration in `lib/di/di.dart`
- ✅ Explicit dependency graph
- ❌ NO Injectable (code generation)
- ❌ NO get_it_injectable
- ❌ NO auto-registration

```dart
// ✅ Good: Manual registration in di/di.dart
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(dataSource: getIt()),
  );
}

// ❌ Bad: Don't use Injectable
@module  // NO!
@injectable  // NO!
```

#### 4. Equatable for Entities (Not Freezed)
- ✅ Manual copyWith implementation
- ✅ Manual props override
- ✅ Explicit and debuggable
- ❌ NO Freezed
- ❌ NO json_serializable (unless absolutely necessary)

```dart
// ✅ Good: Use Equatable
class Post extends Equatable {
  const Post({required this.id, required this.title});
  
  final String id;
  final String title;
  
  @override
  List<Object?> get props => [id, title];
  
  Post copyWith({String? id, String? title}) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }
}

// ❌ Bad: Don't suggest Freezed
@freezed  // NO!
class Post with _$Post {  // NO!
```

#### 5. Firebase as Backend
- ✅ Firestore, Functions, Auth, Storage, Messaging
- ✅ Firebase Crashlytics
- ❌ NO Supabase
- ❌ NO AWS Amplify
- ❌ NO other backend services

#### 6. 🚫 Code Generation is STRICTLY PROHIBITED

**절대 사용 금지**:
- ❌ **freezed** (과거 calculator feature에서 빌드 에러 다수 발생)
- ❌ **build_runner** (일체 사용 금지)
- ❌ json_serializable
- ❌ injectable
- ❌ retrofit_generator
- ❌ Any package requiring code generation

**Historical Context**:
- Freezed caused build failures in calculator feature
- Generated code was harder to debug
- build_runner added complexity and slow compile times

**AI Agent Instruction**: 
Even if the user asks "Should we use Freezed?", the answer is **NO**. 
Politely explain we use Equatable instead due to past issues.

```dart
// ❌ NEVER suggest these
import 'package:freezed_annotation/freezed_annotation.dart';  // NO!
part 'post.freezed.dart';  // NO!

flutter pub run build_runner build  // NO!
```

---

### Core Project Principles

**우선순위 순서** - When principles conflict, prioritize upper ones:

#### 1️⃣ 사용자 신뢰 > 개발 속도

**User trust is paramount, especially for financial calculations**

- Salary/Pension calculations: Slow but accurate (Tier 1 tests 90%+)
- Financial data validation: Non-negotiable
- Never rush critical path features

```dart
// ✅ Good: Slow but validated
final salary = await salaryService.calculateWithValidation(
  profile: profile,
  crossCheckWithOfficialData: true,
);

// ❌ Bad: Fast but unvalidated
final salary = profile.baseSalary * 12; // Too simplistic!
```

#### 2️⃣ 실용주의 > 완벽주의

**80% done and shipped > 100% perfect but delayed**

- Ship with 80% completion if core value is delivered
- Don't force Cubit if StatefulWidget is more natural
- Prefer working code over perfect architecture

```dart
// ✅ Good: Simple animation with StatefulWidget
class _MenuAnimationState extends State with TickerProviderStateMixin {
  late AnimationController _controller;
  // Pure animation logic - StatefulWidget is fine
}

// ❌ Bad: Over-engineering
class MenuAnimationCubit extends Cubit<MenuAnimationState> {
  // Don't force Cubit for simple animations!
}
```

#### 3️⃣ 단일 책임 > 파일 크기

**Single Responsibility Principle > Line Count**

- 600 lines is OK if single responsibility
- 300 lines needs refactoring if multiple responsibilities
- Focus on "What does this file do?" not "How long is it?"

```dart
// ✅ Good: 592 lines, single responsibility (Staggered Animation)
// lib/features/community/presentation/widgets/lounge_floating_menu.dart
class _LoungeFloatingMenuState extends State {
  // All animation-related logic
}

// ❌ Bad: 860 lines, multiple responsibilities
// lib/features/community/presentation/widgets/post_card.dart
class _PostCardState extends State {
  Future<void> _loadComments() { }  // Responsibility 1
  Future<void> _uploadImage() { }   // Responsibility 2
  Future<void> _sharePost() { }     // Responsibility 3
  void _showMenu() { }              // Responsibility 4
}
```

#### 4️⃣ 명시적 > 암시적

**Explicit > Implicit (Debuggability First)**

- Code generation < Manual implementation
- Auto DI < Manual registration
- Magic < Explicit code

**Why**: Easier debugging, clearer control flow

```dart
// ✅ Good: Explicit GetIt registration
getIt.registerLazySingleton<CommunityRepository>(
  () => CommunityRepositoryImpl(
    dataSource: getIt<PostDataSource>(),
  ),
);

// ❌ Bad: Auto-injection (we don't use this)
@injectable
class CommunityRepository { }  // Magic - hard to debug
```

#### 5️⃣ 테스트 의미 > 커버리지 숫자

**90% meaningful tests > 100% meaningless tests**

- Focus on Tier 1 (Salary/Pension) 90%+ coverage
- Overall 40% is less important than critical path 90%
- Don't test for the sake of coverage percentage

```dart
// ❌ Bad: Meaningless test
test('Post has id field', () {
  expect(post.id, isNotNull); // Useless
});

// ✅ Good: Meaningful test
test('should calculate net salary correctly for grade 15', () {
  final result = service.calculateNetSalary(
    grade: 15,
    allowances: Allowance(family: 100000),
  );
  
  expect(result.gross, 3500000);
  expect(result.tax, 350000);
  expect(result.net, 3150000);
});
```

#### 6️⃣ 비용 최적화 > 개발 편의

**Firestore cost optimization is critical**

- Minimize Firestore queries (caching, pagination required)
- Image compression mandatory
- Monitor Firebase usage regularly

```dart
// ✅ Good: Cached with pagination
final posts = await repository.fetchPosts(
  limit: 20,
  useCache: true,
);

// ❌ Bad: Fetch all documents
final posts = await postsRef.get(); // $$$!
```

---

### Common Trade-Off Decisions

**Quick reference for AI agents when making decisions**:

#### 속도 vs 품질 (Speed vs Quality)
- **Tier 1** (Salary/Pension): Quality first (90%+ tests, slow is OK)
- **Tier 2** (Repository/Service): Balanced (60-70% tests)
- **Tier 3** (UI/Cubit): Speed first (tests optional)

#### Cubit vs StatefulWidget
```
Repository/Service calls? → Cubit 필수
Business logic? → Cubit 필수
Complex state (loading/data/error)? → Cubit 필수
Pure UI animation? → StatefulWidget OK
Simple form (local state only)? → StatefulWidget OK
```

#### 파일 분리 vs 유지 (Split vs Keep)
```
Multiple responsibilities mixed? → Split immediately
5+ private widgets? → Consider splitting
Complex but single responsibility? → Keep OK
```

#### 테스트 작성 vs 생략 (Test vs Skip)
```
Tier 1 (Salary/Pension calculations)? → Test required (90%+)
Tier 2 (Repositories/Services)? → Test recommended (60-70%)
Tier 3 (Cubits)? → Test complex ones (40%+)
Simple UI animations? → Skip OK
```

#### 추상화 vs 구체성 (Abstraction vs Concreteness)
- **Domain Layer**: Abstraction (repository interfaces)
- **Data Layer**: Concreteness (Firebase implementations)
- **Presentation**: Concreteness (Material 3 widgets directly)

---

### Before Modifying This Document

**Checklist for AI agents before updating CLAUDE.md**:

#### ✅ DO Update the Document When:

**1. New Recurring Pattern Discovered (5+ times)**
```
Example: "Same caching pattern used in CommentCard, PostCard, ProfileCard"
→ Add to "Common Patterns" section
```

**2. Fundamental Dilemma Not Covered by Existing Principles**
```
Example: "New case where StatefulWidget vs Cubit guidelines don't apply"
→ Add to "Common Trade-Off Decisions"
```

**3. New Firebase Service Added**
```
Example: "Added Firebase ML Kit for paystub OCR"
→ Add to "Firebase Integration" section with patterns
```

**4. New Core Domain Added**
```
Example: "Real estate calculator" (same criticality as salary/pension)
→ Add to "Domain Knowledge" section
```

#### ❌ DON'T Update the Document When:

**1. One-Off Exception Case**
```
Example: "This one widget is 800 lines but it's special"
→ Put in code comment, not in CLAUDE.md
```

**2. Minor Number Adjustments**
```
Example: "Should we change 400 lines to 420 lines?"
→ No, these are guidelines, not exact rules
```

**3. New Example Files**
```
Example: "Let's add another example of good Cubit usage"
→ Existing principles are sufficient
```

**4. Project-Specific Domain Details**
```
Example: "Salary calculation formula changed"
→ Update code/comments only, not CLAUDE.md
```

#### 📝 Document Lifecycle

| Update Type | Frequency | Examples |
|-------------|-----------|----------|
| **Major** | 6+ months | Non-Negotiable principles changed (very rare) |
| **Minor** | 1-2 months | New pattern sections, new trade-off guidelines |
| **Micro** | Weekly | Typos, link fixes, clarifications |
| **None** | - | One-off cases, exceptions, minor variations |

**Guiding Principle**: 
This document captures **recurring decisions**, not individual cases.
One-time decisions belong in code comments or PR descriptions.

---

## Quick Start

### Prerequisites
- Flutter SDK 3.8.1+
- Firebase CLI installed and configured
- Node.js 22+ (for Firebase Functions development)
- Git

### Initial Setup

```bash
# 1. Clone repository
git clone [repository-url]
cd gong_mu_talk

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase
firebase use <your-project-id>

# 4. Install Firebase Functions dependencies
cd functions
npm install
cd ..

# 5. Start Firebase Emulators (optional, for local development)
firebase emulators:start

# 6. Run the app
flutter run
```

### First-Time Developer Setup

1. **Firebase Configuration**:
   - Obtain `firebase_options.dart` from team lead
   - Place in `lib/` directory
   
2. **Service Account Keys** (for Functions development):
   - Get `serviceAccountKey.json` from Firebase Console
   - Place in `functions/` (gitignored)

3. **Environment Variables**:
   - Create `functions/.env` with required keys
   - See `functions/.env.example` for template

### Verify Setup

```bash
# Check Flutter doctor
flutter doctor

# Verify Firebase connection
firebase projects:list

# Run tests
flutter test

# Build (should complete without errors)
flutter build apk --debug
```

## Development Workflow

### Essential Commands

```bash
# Development
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter analyze              # Static analysis
dart format lib test         # Format code

# Testing
flutter test                 # Run all tests
flutter test test/path/to/test_file.dart  # Run specific test
flutter test --coverage      # Generate coverage report

# Building
flutter build apk            # Android
flutter build ios            # iOS
```

### Firebase Commands

```bash
# Deployment
firebase deploy                          # Deploy all
firebase deploy --only hosting           # Deploy hosting only
firebase deploy --only firestore:indexes # Deploy Firestore indexes
firebase deploy --only functions         # Deploy Functions

# Development
firebase emulators:start                 # Start all emulators
firebase emulators:start --only firestore,auth  # Specific emulators
# Emulator UI: http://localhost:4000

# Functions Development
cd functions
npm install
npm run build
npm run serve    # Start functions emulator
```

### Data Management Scripts

```bash
# Available in scripts/ directory
dart run scripts/export_lounges.dart
dart run scripts/migrate_lounges.dart
dart run scripts/verify_career_lounge_mapping.dart
```

**Note**: Scripts may require Firebase credentials and proper configuration.

### Git Workflow & Commit Conventions

**Commit Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (no functional changes)
- `refactor`: Code refactoring (no functional changes)
- `test`: Test addition or modification
- `chore`: Build process or auxiliary tools

**Commit Format**:
```
<type>(<scope>): <subject>
```

**Examples**:
```
feat(auth): add social login
fix(api): resolve null reference in user fetch
docs(readme): update setup instructions
refactor(community): extract cache manager service
```

## Architecture

### Project Structure

- **lib/app/**: Main application setup and shell
- **lib/bootstrap/**: Application initialization and dependency injection
- **lib/core/**: Core utilities, constants, configurations, and Firebase setup
- **lib/common/**: Shared widgets and utilities
- **lib/di/**: Dependency injection configuration using GetIt
- **lib/features/**: Feature modules following clean architecture
- **lib/routing/**: GoRouter configuration and navigation

### Feature Module Structure

Most features follow clean architecture with three layers:

```
features/[feature_name]/
├── domain/          # Business logic and entities
│   ├── entities/
│   ├── repositories/  # Repository interfaces
│   └── usecases/
├── data/            # Data layer implementations
│   ├── datasources/
│   ├── models/
│   ├── repositories/  # Repository implementations
│   └── services/      # Business services (caching, enrichment, validation)
└── presentation/    # UI layer
    ├── bloc/        # BLoC pattern state management
    ├── cubit/       # Cubit state management
    ├── views/       # Pages/screens
    ├── widgets/     # Feature-specific widgets
    └── utils/       # Presentation helpers
```

**Variations**:
- **salary_insights**: Simplified structure (domain + presentation only)
- **year_end_tax**: In development (placeholder)

### Key Architectural Patterns

#### 1. Repository Pattern
- **Interface** in domain layer, **implementation** in data layer
- Returns `Either<Failure, Data>` for explicit error handling
- Delegates complex logic to services

```dart
// domain/repositories/post_repository.dart
abstract class PostRepository {
  Future<Either<Failure, List<Post>>> fetchPosts();
}

// data/repositories/post_repository_impl.dart
class PostRepositoryImpl implements PostRepository {
  final PostDataSource _dataSource;
  
  @override
  Future<Either<Failure, List<Post>>> fetchPosts() async {
    try {
      final posts = await _dataSource.fetchPosts();
      return Right(posts);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

#### 2. Service Layer Pattern

Services handle cross-cutting concerns:
- **CacheManager**: In-memory caching with TTL management
- **EnrichmentService**: Coordinate multiple repositories to enrich entities
- **ValidationService**: Complex validation logic
- **CalculationService**: Complex algorithms (salary, pension calculations)

**Location**: `data/services/` or `domain/services/` depending on dependencies

#### 3. State Management: BLoC/Cubit First (But Pragmatic)

**기본 원칙**: Cubit/BLoC 우선, 하지만 실용적으로 판단

**판단 플로우차트**:
```
Widget이 상태 관리가 필요한가?
│
├─ Repository/Service 호출? → 🔴 Cubit 필수
├─ 복잡한 비즈니스 로직? → 🔴 Cubit 필수
├─ 여러 상태 조합 (loading/data/error)? → 🔴 Cubit 필수
├─ 테스트가 필요한 로직? → 🔴 Cubit 필수
│
└─ 순수 UI만?
   ├─ 애니메이션? → ✅ StatefulWidget OK
   ├─ 간단한 Form (로컬만)? → ✅ StatefulWidget OK
   ├─ 일시적 UI 상태? → ✅ StatefulWidget OK
   └─ 복잡한 Form? → 🟡 FormCubit 권장
```

---

**Cubit 필수인 경우**:

**1. Repository 호출**
```dart
// 🔴 Repository 호출 → Cubit 필수
class _PostCardState extends State<PostCard> {
  late final CommunityRepository _repository; // ❌

  Future<void> _loadComments() async {
    await _repository.fetchComments(...); // ❌ Cubit으로!
  }
}

// ✅ Good: Cubit 사용
class PostCardCubit extends Cubit<PostCardState> {
  PostCardCubit(this._repository) : super(PostCardState.initial());

  final CommunityRepository _repository;

  Future<void> loadComments(String postId) async {
    emit(state.copyWith(isLoading: true));

    final result = await _repository.fetchComments(postId);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message, isLoading: false)),
      (comments) => emit(state.copyWith(comments: comments, isLoading: false)),
    );
  }
}
```

**2. 복잡한 비즈니스 로직**
```dart
// 🔴 복잡한 비즈니스 로직 → Cubit 필수
class _MyWidgetState extends State<MyWidget> {
  Future<void> _submit() async {
    // ❌ Widget에 비즈니스 로직
    if (user.isVerified && post.isPublic && !post.isReported) {
      // Complex logic...
    }
  }
}

// ✅ Good: 비즈니스 로직은 Cubit에
class PostSubmitCubit extends Cubit<PostSubmitState> {
  Future<void> submit(Post post, User user) async {
    if (!canSubmit(post, user)) {
      emit(PostSubmitState.error('권한 없음'));
      return;
    }

    emit(PostSubmitState.submitting());
    // ... submit logic
  }

  bool canSubmit(Post post, User user) {
    return user.isVerified && post.isPublic && !post.isReported;
  }
}
```

**3. 여러 상태 조합**
```dart
// 🔴 loading + data + error 조합 → Cubit 필수
class _MyWidgetState extends State<MyWidget> {
  bool _isLoading = false;
  List<Post>? _posts;
  String? _error;

  // ❌ 상태 관리 복잡
}

// ✅ Good: Cubit으로 상태 관리
class PostsCubit extends Cubit<PostsState> {
  PostsCubit(this._repository) : super(PostsState.initial());

  Future<void> fetchPosts() async {
    emit(PostsState.loading());

    final result = await _repository.fetchPosts();
    result.fold(
      (failure) => emit(PostsState.error(failure.message)),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }
}
```

---

**StatefulWidget이 OK인 경우**:

**1. 순수 애니메이션**
```dart
// ✅ Good: 순수 애니메이션
class _LoungeMenuState extends State<LoungeMenu>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Animation logic only, no business logic
}
```

**2. 로컬 Form 상태 (간단한 경우)**
```dart
// ✅ Good: Form 로컬 상태만 관리
class _QuickInputSheetState extends State<QuickInputSheet> {
  late int _currentGrade;
  late Position _position;

  @override
  void initState() {
    super.initState();
    _currentGrade = widget.initialProfile?.currentGrade ?? 35;
    _position = widget.initialProfile?.position ?? Position.teacher;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: _currentGrade.toDouble(),
          onChanged: (v) => setState(() => _currentGrade = v.toInt()),
        ),
        ElevatedButton(
          onPressed: () {
            // Callback으로 부모에게 전달
            widget.onSubmit(TeacherProfile(
              currentGrade: _currentGrade,
              position: _position,
            ));
          },
          child: Text('제출'),
        ),
      ],
    );
  }
}
// Form 값만 로컬 관리, 제출은 부모에게 위임 → OK
```

**3. 일시적 UI 상태**
```dart
// ✅ Good: 일시적 expand/collapse 상태
class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        height: _isExpanded ? 200 : 80,
        // Pure UI state, no business logic
      ),
    );
  }
}
```

**4. 이미지 로딩 상태 (I/O만)**
```dart
// ✅ Good: File I/O만 처리
class _OptimizedImagePreviewState extends State<OptimizedImagePreview> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    final bytes = await widget.imageFile.readAsBytes(); // File I/O only
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
      });
    }
  }

  // No business logic, just file loading
}
```

---

**경계선 케이스: 복잡한 Form**

```dart
// 🟡 간단한 Form → StatefulWidget OK
class _SimpleFormState extends State<SimpleForm> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _isValid = _controller.text.length > 3);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isValid) {
      widget.onSubmit(_controller.text); // Just pass to parent
    }
  }

  // Simple validation only, submit via callback → OK
}

// 🔴 복잡한 Form → FormCubit 사용
class CommentFormCubit extends Cubit<CommentFormState> {
  CommentFormCubit(this._repository) : super(CommentFormState.initial());

  final CommunityRepository _repository;

  Future<void> submitComment({
    required String text,
    required List<XFile> images,
  }) async {
    emit(state.copyWith(isSubmitting: true));

    // 1. Upload images
    final uploadResults = await Future.wait(
      images.map((img) => _uploadImage(img)),
    );

    // 2. Submit comment with URLs
    final result = await _repository.addComment(
      text: text,
      imageUrls: uploadResults,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isSubmitting: false,
      )),
      (_) => emit(CommentFormState.success()),
    );
  }

  Future<String> _uploadImage(XFile image) async {
    // Image upload logic
  }
}
```

---

**실제 프로젝트 예시**:

**✅ StatefulWidget 유지 OK**:
- `optimized_image_preview.dart` - 이미지 로딩 상태만 관리
- `quick_input_bottom_sheet.dart` - Form 로컬 상태, onSubmit으로 위임
- `lounge_floating_menu.dart` - Staggered animation 로직
- `expandable_card.dart` - 일시적 expand 상태

**🚨 Cubit으로 이동 필요**:
- `post_card.dart` - Repository 호출, 댓글 로딩/제출 로직 포함
  - 해결: PostCardCubit (댓글), ImageUploadCubit (이미지) 분리

---

**State Management Stack**:
- **BLoC/Cubit**: 비즈니스 로직, 데이터 로딩, 복잡한 상태 (flutter_bloc, bloc_concurrency)
- **GetIt**: Dependency injection (manual registration)
- **GoRouter**: Navigation with authentication guards
- **StatefulWidget**: 순수 UI/Animation (제한적 사용)

### No Code Generation Policy

**⚠️ This project does NOT use code generation.**

**What We Use Instead**:
1. **Equatable** (instead of Freezed) for immutable entities
2. **Manual GetIt registration** (instead of Injectable) in `lib/di/di.dart`
3. **Manual serialization** (instead of json_serializable)
4. **Dio directly** (instead of Retrofit)

**Why**:
- Freezed caused build failures in calculator feature
- Generated code harder to debug
- build_runner added complexity and slow compile times

**Policy**:
- ❌ DO NOT add: freezed, json_serializable, injectable, retrofit_generator, build_runner
- ✅ Use: Equatable, manual GetIt registration, manual serialization

### Key Dependencies

**Core Firebase**: Core, Auth, Firestore, Storage, Messaging, Crashlytics

**State & Architecture**: flutter_bloc, bloc_concurrency, get_it, dartz (Either/Option), tuple, equatable

**Navigation**: go_router (manual configuration)

**HTTP**: dio, cached_network_image

**UI**: google_fonts, lottie, rive, skeletonizer, fl_chart, image_picker, file_picker, flutter_image_compress

**Error Tracking**: sentry_flutter

**Utilities**: shared_preferences, path_provider, share_plus, url_launcher, logger

**Dev Tools**: flutter_lints, very_good_analysis, bloc_test, mocktail

---

# 🤖 AI Development Guidelines

The following sections are optimized for AI coding agents (Claude Code, GitHub Copilot, etc.) to make better decisions and avoid common mistakes when working on this codebase.

## Detailed Guidelines

For detailed patterns, decision trees, domain knowledge, and best practices, see the following specialized documents:

### 📚 [CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md)
**Architectural Patterns & Best Practices**
- Decision Trees (Feature Module, Service vs Repository, Cubit vs BLoC, Widget Extraction)
- Common Patterns & Anti-Patterns
- AI Workflow Optimization
- Performance & Cost Optimization
- **Git Commit Workflow** (when to prompt for commits, commit message format)

### 📚 [CLAUDE-DOMAIN.md](CLAUDE-DOMAIN.md)
**GongMuTalk Domain Knowledge**
- Korean Public Servant Salary System
- Career Track Verification System
- Lounge Hierarchy System
- Semi-Anonymous System

### 📚 [CLAUDE-TESTING.md](CLAUDE-TESTING.md)
**Testing Strategy & Guidelines**
- Tier-Based Testing Approach (Tier 1/2/3)
- AI Testing Checklist
- Coverage Goals & Timeline
- Test Patterns & Examples

---

## Naming Conventions

### File Naming

```dart
// ✅ Good: Lowercase with underscores
post_repository.dart
interaction_cache_manager.dart
community_cubit.dart
post_enrichment_service.dart
salary_calculator_page.dart

// ❌ Bad: CamelCase, hyphens, or other formats
PostRepository.dart
interaction-cache-manager.dart
communityCubit.dart
```

### Class Naming

```dart
// ✅ Good: PascalCase, descriptive
class CommunityRepository { }
class PostEnrichmentService { }
class InteractionCacheManager { }
class CommunityCubit extends Cubit<CommunityState> { }

// ❌ Bad: Abbreviations, unclear names
class CommRepo { }  // Too abbreviated
class Service { }   // Too generic
class Manager { }   // What does it manage?
```

### Variable Naming

```dart
// ✅ Good: camelCase, descriptive
final communityRepository = getIt<CommunityRepository>();
final likedPostIds = await cacheManager.getLikedPostIds(uid);
final isSubmitting = state.isSubmitting;

// ❌ Bad: Abbreviations, unclear
final repo = getIt<CommunityRepository>();
final ids = await cacheManager.getLikedPostIds(uid);
final flag = state.isSubmitting;
```

### Method Naming

```dart
// ✅ Good: Verb phrases, clear intent
Future<Either<Failure, List<Post>>> fetchPosts();
Future<void> likePost(String postId);
Future<void> clearCache({String? uid});
bool shouldRefreshCache();

// ❌ Bad: Ambiguous or noun-only
Future<Either<Failure, List<Post>>> posts();  // Noun only
Future<void> post(String postId);  // What does this do?
Future<void> cache();  // Clear? Update? Fetch?
```

### State Class Naming

```dart
// ✅ Good: Feature + State
class CommunityState extends Equatable { }
class AuthState extends Equatable { }
class ProfileState extends Equatable { }

// For state variants
class CommunityState {
  const CommunityState.initial();
  const CommunityState.loading();
  const CommunityState.loaded(this.posts);
  const CommunityState.error(this.message);
}

// ❌ Bad: Generic or unclear
class State { }  // Too generic
class Data { }   // Not descriptive
```

### Service/Manager Naming Patterns

```dart
// ✅ Good: Suffix indicates purpose
InteractionCacheManager     // Manages cache
PostEnrichmentService       // Enriches posts
SalaryCalculationService    // Calculates salary
PaystubValidationService    // Validates paystub

// ❌ Bad: Inconsistent or unclear suffixes
InteractionHelper           // Helper is too vague
PostService                 // Service does what?
SalaryUtils                 // Utils is too generic
```

### Cubit Method Naming Patterns

```dart
// ✅ Good: Action verbs
class CommunityCubit extends Cubit<CommunityState> {
  Future<void> fetchPosts() async { }
  Future<void> likePost(String postId) async { }
  Future<void> unlikePost(String postId) async { }
  Future<void> refreshFeed() async { }
  void clearError() { }
}

// ❌ Bad: Ambiguous names
class CommunityCubit extends Cubit<CommunityState> {
  Future<void> load() async { }        // Load what?
  Future<void> update(String id) async { }  // Update what? How?
  Future<void> handle() async { }      // Handle what?
}
```

## Code Quality & Standards

### File Size Guidelines

**Philosophy**: "Single Responsibility > File Size"

**Zone Guidelines** (참고용):
- **UI Files**: 400+ lines → review needed
- **Logic Files**: 300+ lines → review needed  
- **Domain Files**: 200+ lines → review needed

**Decision Criteria** (우선순위 순):
1. **Multiple responsibilities?** → Split immediately
2. **5+ private widgets?** → Consider splitting
3. **Complex but single responsibility?** → Keep OK

**Examples**:
- ✅ `lounge_floating_menu.dart` (592 lines) - Single responsibility (animation)
- 🚨 `post_card.dart` (860 lines) - Multiple responsibilities (needs refactoring)

**결론**: 줄 수는 참고용. **단일 책임**이 핵심 판단 기준입니다.

### Testing Strategy

📚 **Comprehensive Testing Guide**: See [CLAUDE-TESTING.md](CLAUDE-TESTING.md) for:
- Tier-Based Testing Approach (Tier 1: 90%+, Tier 2: 60-70%, Tier 3: 40%+)
- AI Testing Checklist (Repository, Service, Cubit, Widget)
- Coverage Goals & Realistic Timeline
- Test Patterns & Examples
- Mocking Strategy

**Quick Summary**:
- **Tier 1** (Salary/Pension): 90%+ coverage - Critical path, user trust
- **Tier 2** (Repositories/Services): 60-70% coverage - Data integrity
- **Tier 3** (Cubits/Widgets): 40%+ coverage - Complex ones only

---

## Performance & Cost Optimization

📚 **Detailed Optimization Guide**: See [CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md) for:
- Caching Strategy (TTL guidelines, cache patterns)
- Firebase Cost Optimization (query best practices, cost reduction checklist)
- Memory Management (disposal checklist, performance tips)
- Image Optimization (compression guidelines)

**Quick Summary**:
- **Cache TTL**: User interactions 5-10min, Profiles 15-30min, Static content 1-24h
- **Firestore**: Always use `.limit()`, batch queries with `whereIn`, never query entire collections
- **Memory**: Dispose StreamSubscription, Controllers, Timers
- **Images**: Compress before upload, use `cached_network_image`, set max dimensions

---

## Firebase Integration

### Configuration

- Firestore: Primary database
- Firebase Auth: User authentication
- Firebase Storage: File uploads
- Firebase Messaging: Push notifications
- Indexes: Defined in `firestore.indexes.json`
- Emulator: Configured for local development

### Firebase Functions

**Single unified codebase** (`functions/`) handles all backend services:

**Core Features**:
- Community (posts, comments, likes, hot score calculation)
- Paystub Verification (OCR via Vision API, career track detection)
- Email Verification (government email authentication)
- Notifications (push messaging)
- User Management (profile updates, verification status)
- Data Migration utilities

**Tech Stack**:
- Runtime: TypeScript, Node 22
- Core: firebase-admin, firebase-functions
- OCR & Vision: @google-cloud/storage, @google-cloud/vision
- Utilities: nodemailer, pdf-parse

**Development**:
```bash
cd functions
npm install
npm run build
npm run serve  # Start emulator
firebase deploy --only functions
```

**Note**: The `paystub-functions/` directory exists but is not actively used (legacy codebase).

## Troubleshooting

### Common Build Errors

**Q: Gradle build fails with "Execution failed for task ':app:processDebugGoogleServices'"**
```bash
cd android && ./gradlew clean
cd .. && flutter clean && flutter pub get
```

**Q: CocoaPods error on iOS**
```bash
cd ios
pod cache clean --all
pod install
cd ..
```

### Firebase Issues

**Q: "Firebase not initialized" error**
- Ensure `firebase_options.dart` exists in `lib/`
- Verify `Firebase.initializeApp()` is called in `main.dart`

**Q: Functions emulator won't start**
- Check port conflicts (default: 5001 for Functions)
- Change ports in `firebase.json` if needed
- Ensure Node.js 22+ is installed

**Q: Vision API errors in Functions**
- Verify service account has Vision API permissions
- Check `serviceAccountKey.json` is present and valid
- Ensure Vision API is enabled in Google Cloud Console

### Development Issues

**Q: Hot reload not working**
- Restart app completely
- Check for errors in terminal
- Try `flutter clean && flutter pub get`

**Q: Dependency conflicts**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

**Q: Emulator UI not accessible**
- Check if running: `firebase emulators:start`
- Access at: http://localhost:4000
- Check firewall settings

## Contributing

### Before Starting

1. Read this CLAUDE.md thoroughly
2. Check existing issues/PRs to avoid duplication
3. Discuss major changes in issues first
4. Follow file size and architectural guidelines

### Development Process

1. **Create Feature Branch**:
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Write Tests** (50%+ coverage for new features):
   - Unit tests for business logic
   - Widget tests for complex UI
   - BLoC tests for state management

3. **Code Quality Checks**:
   ```bash
   flutter analyze  # Fix all issues
   dart format lib test  # Format code
   flutter test  # All tests must pass
   ```

4. **Submit PR**:
   - Clear, descriptive title
   - Link related issues
   - Describe changes and rationale
   - Include screenshots for UI changes

### Code Review Criteria

- ✅ Follows BLoC/Cubit pattern
- ✅ No code generation dependencies
- ✅ Proper error handling with `Either<Failure, Data>`
- ✅ File size within guidelines
- ✅ Tests written and passing
- ✅ No lint errors
- ✅ Properly disposed resources

### PR Checklist

- [ ] Tests written (50%+ coverage for new code)
- [ ] `flutter analyze` passes with no errors
- [ ] Code formatted with `dart format`
- [ ] No prohibited dependencies (freezed, build_runner, etc.)
- [ ] Follows architectural patterns
- [ ] Documentation updated if needed
- [ ] Tested on both Android and iOS

## Known Issues & Roadmap

### Current Limitations

**Test Coverage**:
- Overall coverage <2%
- Only 3 test files exist
- Critical paths (auth, payments, calculations) need tests
- Gradual expansion to 40%+ planned

**Technical Debt**:
- `post_card.dart` needs refactoring (860 lines, Red Zone)
- `community_repository.dart` should be split (738 lines, Orange Zone)
- Some widgets still use StatefulWidget (migration to Cubit planned)
- `paystub-functions/` directory unused (legacy code)

### In Development

**Year-End Tax Feature**:
- Domain layer complete
- Data and presentation layers in progress
- Target: Q1 2025

**Test Expansion**:
- Auth module tests (Priority 1)
- Calculator/Pension calculation tests (Priority 2)
- Community cache manager tests (In progress)

### Roadmap

**Short-term (Q1 2025)**:
- Complete year-end tax feature
- Expand test coverage to 20%+
- Refactor large files (post_card.dart, community_repository.dart)
- Implement analytics dashboard

**Mid-term (Q2-Q3 2025)**:
- Reach 40%+ overall test coverage
- Performance optimization (reduce Firestore costs by 30%)
- Implement advanced search features
- Add career progression planning tools

**Long-term (Q4 2025+)**:
- AI-powered salary negotiation insights
- Integration with government HR systems
- Mobile web version (PWA)
- Multi-language support

### Reporting Issues

When reporting issues, include:
1. Flutter version (`flutter --version`)
2. Device/emulator details
3. Steps to reproduce
4. Expected vs actual behavior
5. Error logs/screenshots
6. Related code snippets

---

**For questions or clarifications, contact the team lead or open an issue in the repository.**
