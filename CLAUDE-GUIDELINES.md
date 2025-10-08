# CLAUDE-GUIDELINES.md

**Coding Standards & Contribution Guidelines for GongMuTalk**

This document covers naming conventions, code quality standards, contribution process, and project roadmap.

> 💡 **When to read this**: When writing code, reviewing PRs, or contributing to the project.

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

---

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

## Contributing

### Before Starting

1. Read CLAUDE.md thoroughly
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

---

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

**Test Expansion**:
- Auth module tests (Priority 1)
- Calculator/Pension calculation tests (Priority 2)
- Community cache manager tests (In progress)

### Roadmap

**Short-term (Q1 2025)**:
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

**Related Documents**:
- [CLAUDE.md](CLAUDE.md) - Main overview and principles
- [CLAUDE-ARCHITECTURE.md](CLAUDE-ARCHITECTURE.md) - Architecture details
- [CLAUDE-TESTING.md](CLAUDE-TESTING.md) - Testing strategies
- [CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md) - Common patterns and Git workflow
