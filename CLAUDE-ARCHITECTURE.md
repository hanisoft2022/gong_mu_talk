# CLAUDE-ARCHITECTURE.md

**Architecture & Structure Guide for GongMuTalk**

This document provides detailed architectural patterns, state management strategies, and structural guidelines for the GongMuTalk Flutter application.

> 💡 **When to read this**: When developing new features, refactoring modules, or understanding the project structure.

---

## Project Structure

- **lib/app/**: Main application setup and shell
- **lib/bootstrap/**: Application initialization and dependency injection
- **lib/core/**: Core utilities, constants, configurations, and Firebase setup
- **lib/common/**: Shared widgets and utilities
- **lib/di/**: Dependency injection configuration using GetIt
- **lib/features/**: Feature modules following clean architecture
- **lib/routing/**: GoRouter configuration and navigation

---

## Feature Module Structure

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

---

## Key Architectural Patterns

### 1. Repository Pattern

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

---

### 2. Service Layer Pattern

Services handle cross-cutting concerns:
- **CacheManager**: In-memory caching with TTL management
- **EnrichmentService**: Coordinate multiple repositories to enrich entities
- **ValidationService**: Complex validation logic
- **CalculationService**: Complex algorithms (salary, pension calculations)

**Location**: `data/services/` or `domain/services/` depending on dependencies

---

### 3. State Management: BLoC/Cubit First (But Pragmatic)

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

## Cubit 필수인 경우

### 1. Repository 호출

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

### 2. 복잡한 비즈니스 로직

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

### 3. 여러 상태 조합

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

## StatefulWidget이 OK인 경우

### 1. 순수 애니메이션

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

### 2. 로컬 Form 상태 (간단한 경우)

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

### 3. 일시적 UI 상태

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

### 4. 이미지 로딩 상태 (I/O만)

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

## 경계선 케이스: 복잡한 Form

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

## 실제 프로젝트 예시

### ✅ StatefulWidget 유지 OK
- `optimized_image_preview.dart` - 이미지 로딩 상태만 관리
- `quick_input_bottom_sheet.dart` - Form 로컬 상태, onSubmit으로 위임
- `lounge_floating_menu.dart` - Staggered animation 로직
- `expandable_card.dart` - 일시적 expand 상태

### 🚨 Cubit으로 이동 필요
- `post_card.dart` - Repository 호출, 댓글 로딩/제출 로직 포함
  - 해결: PostCardCubit (댓글), ImageUploadCubit (이미지) 분리

---

## State Management Stack

- **BLoC/Cubit**: 비즈니스 로직, 데이터 로딩, 복잡한 상태 (flutter_bloc, bloc_concurrency)
- **GetIt**: Dependency injection (manual registration)
- **GoRouter**: Navigation with authentication guards
- **StatefulWidget**: 순수 UI/Animation (제한적 사용)

---

## Key Dependencies

**Core Firebase**: Core, Auth, Firestore, Storage, Messaging, Crashlytics

**State & Architecture**: flutter_bloc, bloc_concurrency, get_it, dartz (Either/Option), tuple, equatable

**Navigation**: go_router (manual configuration)

**HTTP**: dio, cached_network_image

**UI**: google_fonts, lottie, rive, skeletonizer, fl_chart, image_picker, file_picker, flutter_image_compress

**Error Tracking**: sentry_flutter

**Utilities**: shared_preferences, path_provider, share_plus, url_launcher, logger

**Dev Tools**: flutter_lints, very_good_analysis, bloc_test, mocktail

---

**Related Documents**:
- [CLAUDE.md](CLAUDE.md) - Main overview and principles
- [CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md) - Common patterns and anti-patterns
- [CLAUDE-TESTING.md](CLAUDE-TESTING.md) - Testing strategies
