# CLAUDE-PATTERNS.md

**Architectural Patterns and Best Practices for GongMuTalk**

This document contains detailed patterns, decision trees, and optimization strategies for AI agents working on this project.

📚 **Main Document**: [CLAUDE.md](CLAUDE.md)

---

## Decision Trees for AI

### When to Create a New Feature Module

```
User requests new functionality
├─ Is it a core user-facing feature? (calculator, community, auth, etc.)
│  └─ YES → Create full feature module with domain/data/presentation
│     └─ Example: "Add retirement planning feature"
│        ├─ lib/features/retirement_planning/domain/
│        ├─ lib/features/retirement_planning/data/
│        └─ lib/features/retirement_planning/presentation/
│
├─ Is it a helper/utility used across features? (formatters, validators, etc.)
│  └─ YES → Add to lib/core/ or lib/common/
│     └─ Example: "Add phone number formatter"
│        └─ lib/core/utils/phone_formatter.dart
│
└─ Is it feature enhancement/bug fix within existing feature?
   └─ YES → Modify existing feature module
      └─ Example: "Add filter to community feed"
         └─ Modify lib/features/community/
```

### Service vs Repository Decision

```
Need to implement data/business logic?
├─ Single data source + CRUD operations?
│  └─ USE REPOSITORY
│     └─ Example: PostRepository.fetchPosts() → Firestore query
│
├─ Multiple repositories coordination?
│  └─ USE SERVICE (EnrichmentService pattern)
│     └─ Example: PostEnrichmentService coordinates:
│        - PostRepository (fetch posts)
│        - InteractionRepository (fetch likes/bookmarks)
│        - CommentRepository (fetch top comments)
│        - CacheManager (check cache)
│
├─ In-memory caching with TTL?
│  └─ USE SERVICE (CacheManager pattern)
│     └─ Example: InteractionCacheManager
│        - Manages cache lifecycle
│        - TTL tracking
│        - Hit/miss statistics
│
├─ Complex calculations without external data?
│  └─ USE SERVICE (CalculationService pattern)
│     └─ Example: SalaryCalculationService
│        - Grade calculation
│        - Allowance computation
│        - Tax deduction
│
└─ Complex validation logic?
   └─ USE SERVICE (ValidationService pattern)
      └─ Example: PaystubValidationService
         - OCR result validation
         - Career track detection
         - Format verification
```

### Cubit vs BLoC Decision

```
Need state management?
├─ Simple state with 1-3 methods?
│  └─ USE CUBIT
│     └─ Example: ThemeCubit (toggleTheme)
│
├─ Complex state with events and event transformers?
│  └─ USE BLOC (rare in this project)
│     └─ Example: SearchBloc with debounce
│
├─ Form handling?
│  └─ USE CUBIT (always)
│     └─ Example: CommentFormCubit
│
└─ API calls and data loading?
   └─ USE CUBIT (default choice)
      └─ Example: CommunityCubit
```

### When to Extract Widgets

```
Widget file size check:
├─ 5+ private widgets in single file?
│  └─ EXTRACT IMMEDIATELY
│     └─ Create widgets/[feature_name]/[concern].dart
│        └─ Example: post_card.dart (885 lines)
│           - Extract to widgets/post/comment_section.dart
│           - Extract to widgets/post/like_button.dart
│           - Extract to widgets/post/share_handler.dart
│
├─ Complex widget with 400+ lines?
│  └─ REVIEW FOR EXTRACTION
│     └─ Check if single responsibility
│        - If multiple concerns → Split by concern
│        - If single concern → Keep together (may be acceptable)
│
└─ Widget reused in 2+ places?
   └─ EXTRACT TO common/ OR widgets/
      └─ Example: LoadingButton used everywhere
         └─ lib/common/widgets/loading_button.dart
```

---

## Common Patterns & Anti-Patterns

### ✅ DO: Use Either Pattern for Error Handling

```dart
// ✅ Good: Repository returns Either
Future<Either<Failure, List<Post>>> fetchPosts() async {
  try {
    final posts = await _dataSource.fetchPosts();
    return Right(posts);
  } on ServerException {
    return Left(ServerFailure());
  } on NetworkException {
    return Left(NetworkFailure());
  } catch (e) {
    return Left(UnknownFailure());
  }
}

// ✅ Good: Cubit handles Either
Future<void> loadPosts() async {
  emit(CommunityState.loading());

  final result = await _repository.fetchPosts();
  result.fold(
    (failure) => emit(CommunityState.error(failure.message)),
    (posts) => emit(CommunityState.loaded(posts)),
  );
}

// ❌ Bad: Throwing exceptions directly
Future<List<Post>> fetchPosts() async {
  final posts = await _dataSource.fetchPosts(); // Throws!
  return posts; // Caller has no type-safe error handling
}
```

### ✅ DO: Manual GetIt Registration

```dart
// ✅ Good: Manual registration in lib/di/di.dart
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Repositories (singletons)
  getIt.registerLazySingleton<CommunityRepository>(
    () => CommunityRepository(
      postDataSource: getIt(),
      cacheManager: getIt(),
      enrichmentService: getIt(),
    ),
  );

  // Cubits (factories - new instance each time)
  getIt.registerFactory<CommunityCubit>(
    () => CommunityCubit(repository: getIt()),
  );
}

// ❌ Bad: Using Injectable or any code generation
@module
abstract class AppModule {
  @lazySingleton
  CommunityRepository get repository; // DON'T DO THIS
}
```

### ✅ DO: Use Equatable for Entities

```dart
// ✅ Good: Equatable for value equality
class Post extends Equatable {
  const Post({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;

  @override
  List<Object?> get props => [id, title, content];

  Post copyWith({
    String? id,
    String? title,
    String? content,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}

// ❌ Bad: Using Freezed
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String title,
  }) = _Post;
} // DON'T DO THIS - project policy prohibits code generation
```

### ✅ DO: Cache Expensive Firestore Queries

```dart
// ✅ Good: Cache with TTL
class InteractionCacheManager {
  static const Duration _cacheTTL = Duration(minutes: 10);
  DateTime? _lastUpdate;
  Set<String>? _cachedLikedPostIds;

  Future<Set<String>> getLikedPostIds(String uid) async {
    if (_shouldRefresh()) {
      _cachedLikedPostIds = await _fetchFromFirestore(uid);
      _lastUpdate = DateTime.now();
    }
    return _cachedLikedPostIds!;
  }

  bool _shouldRefresh() {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!) > _cacheTTL;
  }
}

// ❌ Bad: Always query Firestore
Future<Set<String>> getLikedPostIds(String uid) async {
  return await _fetchFromFirestore(uid); // Expensive every time!
}
```

### ✅ DO: Pagination with Limit

```dart
// ✅ Good: Paginated queries
Future<List<Post>> fetchPosts({required int limit, DocumentSnapshot? lastDoc}) async {
  var query = _firestore
    .collection('posts')
    .orderBy('createdAt', descending: true)
    .limit(limit);

  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc);
  }

  final snapshot = await query.get();
  return snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
}

// ❌ Bad: Fetching all documents
Future<List<Post>> fetchPosts() async {
  final snapshot = await _firestore.collection('posts').get(); // Gets ALL!
  return snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
}
```

### ✅ DO: Dispose Resources

```dart
// ✅ Good: Proper disposal
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  late AnimationController _animController;
  late TextEditingController _textController;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _subscription.cancel();
    _animController.dispose();
    _textController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// ❌ Bad: Memory leaks
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  // ... other resources

  @override
  void dispose() {
    super.dispose(); // Forgot to dispose resources!
  }
}
```

### ✅ DO: Use BLoC/Cubit, Not StatefulWidget for Logic

```dart
// ✅ Good: Business logic in Cubit
class CommentFormCubit extends Cubit<CommentFormState> {
  CommentFormCubit(this._repository) : super(CommentFormState.initial());

  final CommunityRepository _repository;

  void updateText(String text) {
    emit(state.copyWith(text: text));
  }

  Future<void> submitComment(String postId) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await _repository.addComment(postId, state.text);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message, isSubmitting: false)),
      (_) => emit(CommentFormState.success()),
    );
  }
}

// ❌ Bad: Business logic in StatefulWidget
class _CommentFormState extends State<CommentForm> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await repository.addComment(widget.postId, _controller.text); // Hard to test!
    } catch (e) {
      // Error handling mixed with UI
    }
  }
}
```

### ❌ DON'T: Use Code Generation

```dart
// ❌ Bad: Freezed, Injectable, json_serializable
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
} // DON'T DO THIS

// ✅ Good: Manual serialization with Equatable
class Post extends Equatable {
  const Post({required this.id, required this.title});

  final String id;
  final String title;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    title: json['title'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  @override
  List<Object?> get props => [id, title];
}
```

### ❌ DON'T: N+1 Query Loops

```dart
// ❌ Bad: N+1 queries (expensive!)
Future<List<Post>> enrichPostsWithAuthor(List<Post> posts) async {
  final enrichedPosts = <Post>[];
  for (final post in posts) {
    final author = await _firestore.collection('users').doc(post.authorId).get(); // N queries!
    enrichedPosts.add(post.copyWith(author: author));
  }
  return enrichedPosts;
}

// ✅ Good: Batch query with whereIn
Future<List<Post>> enrichPostsWithAuthor(List<Post> posts) async {
  final authorIds = posts.map((p) => p.authorId).toSet().toList();

  // Firestore whereIn supports max 10 items per query
  final authors = <String, User>{};
  for (var i = 0; i < authorIds.length; i += 10) {
    final batch = authorIds.skip(i).take(10).toList();
    final snapshot = await _firestore
      .collection('users')
      .where(FieldPath.documentId, whereIn: batch)
      .get();

    for (final doc in snapshot.docs) {
      authors[doc.id] = User.fromJson(doc.data());
    }
  }

  return posts.map((post) => post.copyWith(author: authors[post.authorId])).toList();
}
```

---

## AI Workflow Optimization

### Which Files to Read for Different Contexts

**Context: Adding a new field to existing feature**

Priority read order:
1. `lib/features/[feature]/domain/entities/[entity].dart` - Check entity structure
2. `lib/features/[feature]/data/models/[model].dart` - Update model serialization
3. `lib/features/[feature]/presentation/cubit/[feature]_cubit.dart` - Update state if needed
4. `lib/features/[feature]/presentation/views/[feature]_page.dart` - Display new field

**Context: Fixing a bug in community feed**

Priority read order:
1. `lib/features/community/presentation/cubit/community_cubit.dart` - Check state logic
2. `lib/features/community/data/community_repository.dart` - Check data fetching
3. `lib/features/community/data/services/post_enrichment_service.dart` - Check enrichment logic
4. `lib/features/community/data/services/interaction_cache_manager.dart` - Check caching
5. `lib/features/community/presentation/widgets/post_card.dart` - Check UI rendering

**Context: Implementing a new calculator feature**

Priority read order:
1. `lib/features/calculator/` - Study existing calculator structure
2. `lib/features/calculator/domain/usecases/` - Understand calculation patterns
3. `lib/features/pension/` - Similar pattern (pension calculator)
4. `lib/core/utils/number_formatter.dart` - Existing number utilities
5. `CLAUDE.md` - Review calculation service pattern

**Context: Adding Firebase function**

Priority read order:
1. `functions/src/index.ts` - Function exports
2. `functions/src/[similar-function].ts` - Study similar function
3. `CLAUDE.md` - Review Firebase Functions section
4. `functions/package.json` - Available dependencies

**Context: Debugging authentication issue**

Priority read order:
1. `lib/features/auth/presentation/cubit/auth_cubit.dart` - Auth state management
2. `lib/features/auth/data/repositories/auth_repository.dart` - Auth repository
3. `lib/core/firebase/firebase_config.dart` - Firebase setup
4. `lib/routing/app_router.dart` - Navigation guards
5. `test/features/auth/data/auth_user_session_test.dart` - Existing auth tests

**Context: Optimizing performance**

Priority read order:
1. `CLAUDE.md` - Performance & Cost Optimization section
2. `lib/features/community/data/services/interaction_cache_manager.dart` - Caching example
3. `lib/core/utils/image_compression_util.dart` - Image optimization example
4. Large repository files (check for optimization opportunities)

### Reading Strategy by File Size

- **<200 lines**: Read entire file
- **200-500 lines**: Read class signatures, then specific methods as needed
- **500-800 lines**: Read file structure first, then targeted sections
- **800+ lines**: File should be refactored, but if reading: focus on specific methods/classes only

---

## Performance & Cost Optimization

### Caching Strategy

**When to Cache**:
- Frequently accessed, rarely changed data
- Expensive Firestore queries (multiple document reads)
- User-specific interactions (likes, bookmarks, view history)
- Computed/aggregated data

**Cache TTL Guidelines**:
- Real-time data (chat): No cache or 30 seconds
- User interactions (likes, bookmarks): 5-10 minutes
- User profiles: 15-30 minutes
- Static content (app settings): 1-24 hours

**Example Pattern**:
```dart
class InteractionCacheManager {
  static const Duration _cacheTTL = Duration(minutes: 10);
  DateTime? _lastCacheUpdate;
  
  bool shouldRefreshCache() {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheTTL;
  }
  
  Map<String, int> getCacheStats() {
    return {
      'hitCount': _cacheHitCount,
      'missCount': _cacheMissCount,
      'savedCost': _cacheHitCount * 2, // Each hit saves 2 Firestore reads
    };
  }
}
```

### Firebase Cost Optimization

**Query Best Practices**:
```dart
// ✅ Good: Use limit for pagination
await postsRef.orderBy('createdAt', descending: true).limit(20).get();

// ✅ Good: Batch queries
await postsRef.where(FieldPath.documentId, whereIn: postIds.take(10)).get();

// ❌ Bad: N+1 queries
for (final postId in postIds) {
  await postsRef.doc(postId).get(); // Expensive!
}

// ❌ Bad: No pagination
await postsRef.orderBy('createdAt').get(); // Gets ALL documents!
```

**Cost Reduction Checklist**:
- ✅ Implement pagination with `.limit()`
- ✅ Cache frequently accessed data
- ✅ Use composite indexes for complex queries
- ✅ Batch reads using `whereIn` (max 10 items per query)
- ❌ Never query entire collections
- ❌ Avoid `.get()` calls inside loops

### Memory Management

**Must Dispose**:
- StreamSubscription
- AnimationController
- TextEditingController
- Timer
- ScrollController
- FocusNode

**Performance Best Practices**:
```dart
// ✅ Use const for static widgets
const Text('Static Label');

// ✅ Extract widgets to reduce rebuilds
class _StaticHeader extends StatelessWidget {
  const _StaticHeader();
}

// ✅ Use keys for list items
ListView.builder(
  itemBuilder: (context, index) {
    return PostCard(
      key: ValueKey(posts[index].id),
      post: posts[index],
    );
  },
);
```

### Image Optimization

**Compression Guidelines**:
```dart
enum ImageCompressionType {
  profile,   // 90%
  post,      // 85%
  comment,   // 80%
  thumbnail, // 70%
}
```

**Best Practices**:
- ✅ Compress before upload
- ✅ Use `cached_network_image` for network images
- ✅ Set `maxWidth` and `maxHeight` when picking
- ✅ Use thumbnails for list views
- ❌ Don't upload raw camera images (can be 5-10MB!)

---

## When to Reference This Document

**AI agents should read CLAUDE-PATTERNS.md when**:
- Making architectural decisions (Repository vs Service)
- Choosing between Cubit and BLoC
- Deciding whether to extract widgets
- Implementing caching strategies
- Optimizing Firestore queries
- Questions about code patterns and anti-patterns

**Don't need to read if**:
- Understanding domain knowledge (see CLAUDE-DOMAIN.md)
- Testing strategy questions (see CLAUDE-TESTING.md)
- Quick start or setup questions (see CLAUDE.md)
