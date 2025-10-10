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

### Color System Guidelines

**Philosophy**: "Semantic Meaning > Hardcoded Values"

GongMuTalk uses a **centralized color system** (`AppColors`) to ensure consistency across the app.

#### 🎨 Color Categories

**1. Brand Colors** - 브랜드 아이덴티티
```dart
AppColors.primary           // #0064FF - Toss blue (main brand color)
AppColors.primaryDark       // #0B1E3E - Dark variant
AppColors.secondary         // #5E8BFF - Secondary actions
AppColors.accent            // #00C4B3 - Accent highlights
```

**2. Surface Colors** - 배경 및 컨테이너
```dart
// Light mode
AppColors.surface           // #F3F4F8 - Main background
AppColors.surfaceBright     // #FFFFFF - Cards, elevated surfaces
AppColors.surfaceSubtle     // #E8EBF3 - Input fields, subtle containers

// Dark mode
AppColors.surfaceDark       // #0F1726 - Main background
AppColors.surfaceDarkElevated  // #171F2F - App bars, elevated surfaces
AppColors.surfaceDarkCard   // #1F293C - Cards, containers
```

**3. Semantic Colors** - 상태 및 피드백
```dart
// Status
AppColors.success / successLight / successDark  // Green - 성공, 완료, 검증
AppColors.warning / warningLight / warningDark  // Amber - 주의, 확인 필요
AppColors.error / errorLight / errorDark        // Red - 오류, 실패
AppColors.info / infoLight / infoDark           // Blue - 정보, 안내
```

**4. Emotional/Action Colors** - 커뮤니티 기능
```dart
// Like
AppColors.like / likeLight / likeDark           // Pink - 좋아요, 인기

// Highlight
AppColors.highlight / highlightLight / highlightDark  // Orange - 강조, 인기글
AppColors.highlightBgLight / highlightBgDark    // Yellow/Amber - 하이라이트 배경
AppColors.highlightBorderLight / highlightBorderDark  // 하이라이트 테두리
```

**5. Financial Colors** - 계산기 기능 (중요!)
```dart
AppColors.positive / positiveLight / positiveDark  // Green - 수익, 증가, 실수령액
AppColors.negative / negativeLight / negativeDark  // Red - 손실, 감소, 공제액
AppColors.neutral / neutralLight / neutralDark     // Gray - 중립, 기준값, 총액
```

**6. Monochrome** - Black & White variants
```dart
AppColors.black / blackSoft / blackAlpha50
AppColors.white / whiteSoft / whiteAlpha50 / whiteAlpha70
```

#### 📋 Usage Guidelines

**✅ DO:**
```dart
// Use semantic colors from AppColors
Icon(Icons.error_outline, color: AppColors.error)
Text(style: TextStyle(color: AppColors.neutral))
Container(color: AppColors.highlightBgLight)

// Use theme-based colors for consistency
Icon(Icons.info, color: Theme.of(context).colorScheme.primary)
Text(style: Theme.of(context).textTheme.bodyMedium)
```

**❌ DON'T:**
```dart
// Don't use hardcoded Color() values
Icon(Icons.error, color: Color(0xFFEF4444))  // ❌

// Don't use Material default colors directly
Icon(Icons.error, color: Colors.red)  // ❌
Container(color: Colors.grey[600])    // ❌

// Don't create ad-hoc alpha values
Divider(color: Colors.grey.withValues(alpha: 0.3))  // ❌
```

#### 🎯 Decision Tree: "언제 어떤 색상 쓸까?"

```
상태 표시가 필요한가?
├─ 성공/완료 → AppColors.success
├─ 경고/주의 → AppColors.warning
├─ 오류/실패 → AppColors.error
└─ 정보/안내 → AppColors.info

금융 데이터인가? (Calculator)
├─ 증가/수익/실수령 → AppColors.positive
├─ 감소/손실/공제 → AppColors.negative
└─ 중립/총액/기준 → AppColors.neutral

커뮤니티 액션인가?
├─ 좋아요 → AppColors.like
├─ 하이라이트/인기 → AppColors.highlight
└─ 하이라이트 배경 → AppColors.highlightBg{Light|Dark}

기본 UI 요소인가?
├─ 강조 필요 → Theme.of(context).colorScheme.primary
├─ 보조 액션 → Theme.of(context).colorScheme.secondary
├─ 텍스트 주요 → Theme.of(context).colorScheme.onSurface
├─ 텍스트 보조 → Theme.of(context).colorScheme.onSurfaceVariant
└─ 배경/카드 → Theme.of(context).colorScheme.surface

흑백이 필요한가?
└─ AppColors.{black|white}{Soft|Alpha50|Alpha70}
```

#### 🔄 Light/Dark Mode Handling

```dart
// ✅ Good: Use brightness-aware colors
final bgColor = Theme.of(context).brightness == Brightness.dark
    ? AppColors.highlightBgDark
    : AppColors.highlightBgLight;

// ✅ Better: Use theme variants when possible
final errorColor = Theme.of(context).brightness == Brightness.dark
    ? AppColors.errorLight  // Lighter error for dark mode
    : AppColors.error;

// ✅ Best: Use theme color scheme directly
final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
```

#### 🎨 Adding New Colors

**Before adding new colors**, check:
1. ✅ **Is this a recurring pattern?** (used 3+ times across features)
2. ✅ **Does it have semantic meaning?** (not just "dark blue")
3. ✅ **Is it part of brand identity?** (finance, status, emotion)

**If yes to all 3**, add to `lib/core/constants/app_colors.dart`:
```dart
// Example: Adding "Premium" tier color
static const Color premium = Color(0xFFD4AF37);  // Gold
static const Color premiumLight = Color(0xFFE5C158);
static const Color premiumDark = Color(0xFFC19A2E);
```

**If no**, use theme colors or keep it local to the widget.

#### 📚 References

- Color definitions: `lib/core/constants/app_colors.dart`
- Theme integration: `lib/core/theme/app_theme.dart`
- Material 3 colors: [Material Design Color System](https://m3.material.io/styles/color/system/overview)

### Calculator Domain Rules

**Philosophy**: "Single Source of Truth > Duplicate Logic"

GongMuTalk의 급여/연금 계산기는 **정확성**이 최우선입니다. 계산 로직의 일관성을 위해 **Single Source of Truth** 패턴을 엄격히 준수합니다.

#### 🧮 Calculation Core (calculation_core/)

**계산 로직의 단일 진입점** - 모든 서비스는 이 클래스들을 통해 계산해야 합니다.

**1. ServiceYearsCalculator** - 재직년수 계산
```dart
// ✅ ALWAYS use ServiceYearsCalculator
final serviceInfo = ServiceYearsCalculator.calculate(
  startDate,
  endDate,
);
final serviceYears = serviceInfo.fullYears;

// ❌ NEVER calculate manually
final serviceYears = endDate.year - startDate.year;  // ❌ Wrong!
final serviceYears = (totalDays / 365).floor();      // ❌ Wrong!
final serviceYears = profile.getServiceYears();      // ❌ Wrong!
```

**계산 방식**:
- 일수 기반 정확 계산 (365일 = 1년)
- 만 나이 방식 적용
- 테스트 커버리지: 100% (18/18 tests)

**2. HolidayPaymentTable** - 명절상여금 지급 월
```dart
// ✅ ALWAYS use HolidayPaymentTable
final holidayBonus = HolidayPaymentTable.calculateHolidayBonus(
  baseSalary: baseSalary,
  year: year,
  month: month,
);

// ❌ NEVER hardcode lunar calendar mapping
final lunarHolidays = {
  2025: [1, 10],  // ❌ Wrong! Incomplete data
  // ...
};
```

**데이터 범위**:
- 2025~2073년 (49년치)
- 한국천문연구원 음력-양력 변환 데이터 기반
- **2033년 업데이트 필요** (2074-2075년 추가)

**연간 명절상여금**:
- 설날 + 추석 = 본봉 × 60% × 2 = 본봉 × 1.2
- 38년 재직 시 약 114M원 (누락 시 큰 손실!)

#### 📋 Calculator Services Layer

**계산 서비스 계층** - calculation_core를 사용하여 복잡한 계산 수행

**SalaryCalculationService**:
- 연도별 급여 계산 (`calculateAnnualSalaries`)
- 생애 급여 계산 (`calculateLifetimeSalary`)
- 각종 수당 계산 (정근수당, 가족수당, 교원연구비 등)

**MonthlyBreakdownService**:
- 월별 실수령액 계산 (`calculateMonthlyBreakdown`)
- 12개월 상세 급여명세서

**PensionCalculationService**:
- 연금 예상액 계산 (`calculatePension`)
- 조기연금 시나리오 비교

**TaxCalculationService**:
- 소득세 및 지방소득세
- 4대보험 (연금, 건강, 장기요양, 고용)

#### 🚨 Critical Rules

**Rule 1: Never Duplicate Calculation Logic**
```dart
// ❌ BAD: Duplicating service years calculation
final serviceYears1 = year - profile.employmentStartDate.year;
final serviceYears2 = (totalDays / 365).floor();
final serviceYears3 = profile.getServiceYears();

// ✅ GOOD: Single source of truth
final serviceYears = ServiceYearsCalculator.calculate(...).fullYears;
```

**Rule 2: Always Include Holiday Bonus in Lifetime Salary**
```dart
// ❌ BAD: Missing 114M won for 38-year career
final annualTotalPay = (netPay * 12) + performanceBonus;

// ✅ GOOD: Complete calculation
final holidayBonus = HolidayPaymentTable.calculateAnnualHolidayBonus(
  baseSalary: basePay,
  year: year,
);
final annualTotalPay = (netPay * 12) + performanceBonus + holidayBonus;
```

**Rule 3: Use Accurate Age Calculation for Benefits**
```dart
// ❌ BAD: Simplified age calculation
final age = currentYear - birthYear;

// ✅ GOOD: Precise age with month consideration
final age = ServiceYearsCalculator.calculateAge(
  birthYear,
  birthMonth,
  DateTime(currentYear, currentMonth, 1),
);
```

#### 🧪 Testing Requirements

**Tier 1: Critical Path (90%+ coverage required)**
- `ServiceYearsCalculator`: 100% (18/18 tests) ✅
- `HolidayPaymentTable`: 100% (25/25 tests) ✅
- Salary calculation services: 90%+ required
- Pension calculation services: 90%+ required

**Why so strict?**
- User trust: 급여/연금 계산 오류는 신뢰 손실
- Financial impact: 38년 재직 시 114M원 차이 가능
- Legal compliance: 정확한 세금/보험료 계산 필수

#### 📂 File Organization

```
lib/features/calculator/domain/
├── calculation_core/           # Single Source of Truth
│   ├── service_years_calculator.dart    # 재직년수 통합 계산
│   └── (future) calculation_context.dart
├── constants/
│   ├── salary_table.dart
│   ├── holiday_payment_table.dart       # 명절상여금 (49년치)
│   └── income_redistribution_table.dart
├── services/                   # Complex calculations
│   ├── salary_calculation_service.dart
│   ├── monthly_breakdown_service.dart
│   ├── pension_calculation_service.dart
│   └── tax_calculation_service.dart
└── entities/                   # Domain models
    ├── teacher_profile.dart
    ├── annual_salary.dart
    ├── monthly_net_income.dart
    └── pension_estimate.dart
```

#### 🔄 Migration Notes

**Before refactor (Old code)**:
- 3 different service years calculations (inconsistent!)
- 6 years of holiday data (insufficient!)
- Holiday bonus missing from lifetime salary (114M won loss!)

**After refactor (Current code)**:
- ✅ Single `ServiceYearsCalculator` for all calculations
- ✅ 49 years of `HolidayPaymentTable` data (2025-2073)
- ✅ Holiday bonus included in lifetime salary

**Impact**: 24세 입직 교사 (38년 재직) → +114M won accuracy improvement!

---

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
