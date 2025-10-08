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

---

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

## 🚫 Non-Negotiable Principles

**These are permanent project decisions** - AI should NEVER suggest alternatives:

### 1. Clean Architecture (Domain/Data/Presentation)

- ✅ Repository interfaces in domain layer
- ✅ Implementations in data layer
- ✅ Clear separation of concerns
- ❌ NO mixing layers
- ❌ NO direct Firebase calls from presentation

### 2. BLoC/Cubit for State Management

- ✅ BLoC/Cubit only for all state management
- ✅ flutter_bloc, bloc_concurrency
- ❌ NO Riverpod, Provider, GetX, Redux, MobX

### 3. GetIt for Manual Dependency Injection

- ✅ Manual registration in `lib/di/di.dart`
- ✅ Explicit dependency graph
- ❌ NO Injectable (code generation)
- ❌ NO get_it_injectable
- ❌ NO auto-registration

### 4. Equatable & No Code Generation

**Use Equatable for entities** - NO code generation tools:
- ✅ Manual copyWith implementation
- ✅ Manual props override
- ✅ Explicit and debuggable
- ❌ NO Freezed, json_serializable, injectable, retrofit_generator, build_runner

**Historical Context**:
- Freezed caused build failures in calculator feature
- Generated code harder to debug
- build_runner added complexity and slow compile times

**AI Agent Instruction**:
Even if the user asks "Should we use Freezed?", the answer is **NO**.
Politely explain we use Equatable instead due to past issues.

---

## Core Project Principles

**우선순위 순서** - When principles conflict, prioritize upper ones:

### 1️⃣ 사용자 신뢰 > 개발 속도

**User trust is paramount, especially for financial calculations**

- Salary/Pension calculations: Slow but accurate (Tier 1 tests 90%+)
- Financial data validation: Non-negotiable
- Never rush critical path features

### 2️⃣ 실용주의 > 완벽주의

**80% done and shipped > 100% perfect but delayed**

- Ship with 80% completion if core value is delivered
- Don't force Cubit if StatefulWidget is more natural
- Prefer working code over perfect architecture

### 3️⃣ 단일 책임 > 파일 크기

**Single Responsibility Principle > Line Count**

- 600 lines is OK if single responsibility
- 300 lines needs refactoring if multiple responsibilities
- Focus on "What does this file do?" not "How long is it?"

### 4️⃣ 명시적 > 암시적

**Explicit > Implicit (Debuggability First)**

- Code generation < Manual implementation
- Auto DI < Manual registration
- Magic < Explicit code

### 5️⃣ 테스트 의미 > 커버리지 숫자

**90% meaningful tests > 100% meaningless tests**

- Focus on Tier 1 (Salary/Pension) 90%+ coverage
- Overall 40% is less important than critical path 90%
- Don't test for the sake of coverage percentage

### 6️⃣ 비용 최적화 > 개발 편의

**Firestore cost optimization is critical**

- Minimize Firestore queries (caching, pagination required)
- Image compression mandatory
- Monitor Firebase usage regularly

---

## Common Trade-Off Decisions

**Quick reference for AI agents when making decisions**:

### 속도 vs 품질 (Speed vs Quality)
- **Tier 1** (Salary/Pension): Quality first (90%+ tests, slow is OK)
- **Tier 2** (Repository/Service): Balanced (60-70% tests)
- **Tier 3** (UI/Cubit): Speed first (tests optional)

### Cubit vs StatefulWidget
```
Repository/Service calls? → Cubit 필수
Business logic? → Cubit 필수
Complex state (loading/data/error)? → Cubit 필수
Pure UI animation? → StatefulWidget OK
Simple form (local state only)? → StatefulWidget OK
```

### 파일 분리 vs 유지 (Split vs Keep)
```
Multiple responsibilities mixed? → Split immediately
5+ private widgets? → Consider splitting
Complex but single responsibility? → Keep OK
```

### 테스트 작성 vs 생략 (Test vs Skip)
```
Tier 1 (Salary/Pension calculations)? → Test required (90%+)
Tier 2 (Repositories/Services)? → Test recommended (60-70%)
Tier 3 (Cubits)? → Test complex ones (40%+)
Simple UI animations? → Skip OK
```

### 추상화 vs 구체성 (Abstraction vs Concreteness)
- **Domain Layer**: Abstraction (repository interfaces)
- **Data Layer**: Concreteness (Firebase implementations)
- **Presentation**: Concreteness (Material 3 widgets directly)

---

## 📚 AI Agent: 언제 어떤 문서를 읽을까?

**기본**: CLAUDE.md만 읽고 시작 (이 파일)

**추가로 읽어야 할 때**:

### 🏗️ 새 기능/모듈 개발
→ **[CLAUDE-ARCHITECTURE.md](CLAUDE-ARCHITECTURE.md)** 참조
- Project Structure
- Feature Module Structure
- State Management 상세 (Cubit vs StatefulWidget)
- Repository & Service Patterns

### ⚙️ 개발환경 설정/문제
→ **[CLAUDE-SETUP.md](CLAUDE-SETUP.md)** 참조
- Quick Start
- Firebase Setup
- Troubleshooting

### 📝 네이밍/코드스타일
→ **[CLAUDE-GUIDELINES.md](CLAUDE-GUIDELINES.md)** 참조
- Naming Conventions
- Code Quality Standards
- Contributing Guidelines
- Known Issues & Roadmap

### 🎯 패턴/최적화/Git
→ **[CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md)** 참조
- Decision Trees
- Common Patterns & Anti-Patterns
- Performance & Cost Optimization
- Git Commit Workflow

### 🧪 테스트 작성
→ **[CLAUDE-TESTING.md](CLAUDE-TESTING.md)** 참조
- Tier-Based Testing Approach
- AI Testing Checklist
- Test Patterns & Examples

### 💼 도메인 로직 이해
→ **[CLAUDE-DOMAIN.md](CLAUDE-DOMAIN.md)** 참조
- Korean Public Servant Salary System
- Career Track Verification
- Lounge Hierarchy System

**중요**: 대부분의 간단한 작업은 CLAUDE.md만으로 충분합니다!

---

## Before Modifying This Document

**Checklist for AI agents before updating CLAUDE.md**:

### ✅ DO Update the Document When:

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

### ❌ DON'T Update the Document When:

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

### 📝 Document Lifecycle

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

**For questions or clarifications, contact the team lead or open an issue in the repository.**
