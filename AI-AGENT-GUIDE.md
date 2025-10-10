# AI Agent Quick Guide: 접근 레벨 기반 기능 제어

이 문서는 AI 코딩 에이전트가 공무톡 앱에서 **인증 레벨 기반 기능 제어**를 빠르게 구현할 수 있도록 돕는 가이드입니다.

---

## 🎯 Quick Start (5분 이해)

### 시스템 개요

공무톡은 **4단계 인증 레벨**로 기능 접근을 제어합니다:

| Level | 이름 | 설명 | 권한 |
|-------|------|------|------|
| 0 | Guest | 비회원 | 라운지 읽기, 계산기 요약 |
| 1 | Member | 회원 (로그인만) | Level 0과 동일 |
| 2 | EmailVerified | 공직자 메일 인증 | 라운지 쓰기, 계산기 상세 |
| 3 | CareerVerified | 직렬 인증 (급여명세서) | Level 2 + 전문 라운지 + 30년 시뮬레이션 |

### 핵심 파일 3개

```
lib/features/calculator/domain/entities/feature_access_level.dart
lib/features/calculator/presentation/widgets/common/feature_card.dart
lib/features/calculator/presentation/widgets/common/feature_button.dart
```

---

## 📦 사용법: 3가지 패턴

### 패턴 1️⃣: 전체 카드/페이지 잠금

```dart
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_card.dart';

// ✅ DO: 전체 위젯을 FeatureCard로 감싸기
FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  featureName: '월별 상세 분석',
  child: MonthlyDetailWidget(),
)
```

**언제 사용?**
- 탭 전체를 잠그고 싶을 때
- 카드 전체를 잠그고 싶을 때
- 페이지 전체를 잠그고 싶을 때

### 패턴 2️⃣: 버튼만 잠금

```dart
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_button.dart';

// ✅ DO: 버튼을 FeatureButton으로 교체
FeatureButton(
  requiredLevel: FeatureAccessLevel.careerVerified,
  featureName: '30년 시뮬레이션',
  icon: Icon(Icons.analytics),
  onPressed: () => Navigator.push(...),
  child: Text('30년 시뮬레이션'),
)
```

**언제 사용?**
- 요약은 보여주되, 상세 버튼만 잠그고 싶을 때
- 여러 버튼 중 일부만 잠그고 싶을 때

### 패턴 3️⃣: 조건부 로직

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';

// ✅ DO: BlocBuilder + canAccess 사용
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, authState) {
    if (authState.canAccess(FeatureAccessLevel.careerVerified)) {
      return DetailedChart();
    }
    return SummaryChart();
  },
)
```

**언제 사용?**
- 잠금 화면 대신 다른 위젯을 보여주고 싶을 때
- 복잡한 조건 로직이 필요할 때

---

## 🔧 구현 가이드

### Step 1: 어떤 패턴을 쓸지 결정

**질문 체크리스트:**

1. **전체를 잠가야 하나? (패턴 1)**
   - YES → `FeatureCard` 사용
   - NO → 2번 질문으로

2. **버튼만 잠가야 하나? (패턴 2)**
   - YES → `FeatureButton` 사용
   - NO → 3번 질문으로

3. **잠금 화면 대신 다른 UI를 보여줘야 하나? (패턴 3)**
   - YES → `BlocBuilder + canAccess` 사용

### Step 2: 레벨 선택

**4가지 레벨 중 하나를 선택:**

```dart
// Level 0-1: 로그인 필요
FeatureAccessLevel.member

// Level 2: 공직자 메일 인증 (라운지 쓰기, 계산기 상세)
FeatureAccessLevel.emailVerified

// Level 3: 직렬 인증 (전문 라운지, 30년 시뮬레이션)
FeatureAccessLevel.careerVerified
```

**선택 기준:**

- **EmailVerified (Level 2)**
  - 상세 분석, 월별/연별 breakdown
  - 5-10년 시뮬레이션
  - 라운지 글/댓글 작성

- **CareerVerified (Level 3)**
  - 30년 생애 시뮬레이션
  - 전문 라운지 접근
  - 차트/그래프 분석

### Step 3: 코드 작성

```dart
// 1. Import 추가
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_card.dart';

// 2. 기존 위젯을 감싸기
// ❌ BEFORE:
return DetailedAnalysisWidget();

// ✅ AFTER:
return FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  featureName: '상세 분석',
  child: DetailedAnalysisWidget(),
);
```

---

## 📚 실전 예제

### 예제 1: 계산기 탭 잠금

**요구사항:** "월별 분석 탭은 공직자 메일 인증 후 이용 가능"

```dart
// salary_analysis_page.dart

import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_card.dart';

TabBarView(
  children: [
    // ✅ 탭 1: 잠김
    FeatureCard(
      requiredLevel: FeatureAccessLevel.emailVerified,
      featureName: '월별 상세 분석',
      child: MonthlyBreakdownTab(),
    ),

    // ✅ 탭 2: 잠김
    FeatureCard(
      requiredLevel: FeatureAccessLevel.emailVerified,
      featureName: '연봉 상세 분석',
      child: AnnualBreakdownTab(),
    ),
  ],
)
```

### 예제 2: 버튼만 잠금

**요구사항:** "카드는 보여주되, [상세 분석] 버튼만 잠금"

```dart
// current_salary_card.dart

import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_button.dart';

Card(
  child: Column(
    children: [
      Text('월 평균 급여: 350만원'),

      // ✅ 버튼만 잠금
      FeatureButton(
        requiredLevel: FeatureAccessLevel.emailVerified,
        featureName: '상세 분석',
        icon: Icon(Icons.analytics),
        onPressed: () => Navigator.push(...),
        child: Text('상세 분석'),
      ),
    ],
  ),
)
```

### 예제 3: 조건부 차트

**요구사항:** "직렬 인증 완료자만 차트 표시, 나머지는 텍스트만"

```dart
// lifetime_earnings_page.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';

BlocBuilder<AuthCubit, AuthState>(
  builder: (context, authState) {
    // ✅ Level 3: 차트 표시
    if (authState.canAccess(FeatureAccessLevel.careerVerified)) {
      return LineChart(data);
    }

    // ❌ Level 0-2: 숫자만 표시
    return Text('생애 예상 소득: 15억원\n\n차트는 직렬 인증 후 이용 가능합니다');
  },
)
```

---

## ❌ 흔한 실수 & 해결

### 실수 1: Import 누락

```dart
// ❌ BAD: Import 없이 사용
FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  child: MyWidget(),
)

// ✅ GOOD: Import 추가
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_card.dart';

FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  child: MyWidget(),
)
```

### 실수 2: featureName 누락

```dart
// ❌ BAD: featureName 없음 → "이 기능" 으로 표시됨
FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  child: MyWidget(),
)

// ✅ GOOD: 명확한 이름 제공
FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  featureName: '월별 상세 분석',  // ← 추가
  child: MyWidget(),
)
```

### 실수 3: 잘못된 레벨 선택

```dart
// ❌ BAD: 30년 시뮬레이션인데 emailVerified 사용
FeatureCard(
  requiredLevel: FeatureAccessLevel.emailVerified,
  featureName: '30년 시뮬레이션',
  child: LifetimeSimulation(),
)

// ✅ GOOD: 30년 시뮬레이션은 careerVerified
FeatureCard(
  requiredLevel: FeatureAccessLevel.careerVerified,
  featureName: '30년 시뮬레이션',
  child: LifetimeSimulation(),
)
```

---

## 🎨 전체 구조 이해 (선택)

AI 에이전트는 이 섹션을 읽을 필요 없음. 필요 시에만 참조.

### 시스템 구조

```
┌─────────────────────────────────────────────────┐
│           사용자 (User)                          │
└─────────────────┬───────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────┐
│     AuthState (BLoC)                             │
│  - isLoggedIn                                    │
│  - isGovernmentEmailVerified                     │
│  - isCareerTrackVerified                         │
│  - currentAccessLevel (extension)                │
│  - canAccess(level) (extension)                  │
└─────────────────┬───────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────┐
│  FeatureAccessLevel (Enum)                       │
│  - guest (0)                                     │
│  - member (1)                                    │
│  - emailVerified (2)                             │
│  - careerVerified (3)                            │
└─────────────────┬───────────────────────────────┘
                  │
         ┌────────┴────────┐
         ↓                 ↓
  FeatureCard       FeatureButton
  (전체 잠금)         (버튼만 잠금)
         ↓                 ↓
  LockedFeatureView  (다이얼로그)
  (자물쇠 화면)
```

### 파일 위치

```
lib/
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── cubit/
│   │           ├── auth_cubit.dart         # FeatureAccessLevel import 추가
│   │           └── auth_state.dart         # canAccess() extension
│   │
│   ├── calculator/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── feature_access_level.dart  # 4-level enum
│   │   │
│   │   └── presentation/
│   │       └── widgets/
│   │           └── common/
│   │               ├── feature_card.dart       # 전체 잠금
│   │               ├── feature_button.dart     # 버튼 잠금
│   │               └── locked_feature_view.dart # 자물쇠 화면
│   │
│   └── profile/
│       └── domain/
│           └── user_profile.dart            # isCareerTrackVerified 필드
```

---

## 🔍 디버깅 가이드

### 문제: "접근 가능한데도 잠김"

**확인 사항:**
1. AuthState가 제대로 업데이트되었는지 확인
2. BlocProvider가 올바른 위치에 있는지 확인
3. canAccess() 로직이 올바른지 확인

```dart
// 디버깅용 코드 추가
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, authState) {
    print('Current level: ${authState.currentAccessLevel}');
    print('Required level: $requiredLevel');
    print('Can access: ${authState.canAccess(requiredLevel)}');

    return FeatureCard(...);
  },
)
```

### 문제: "Import 오류"

```dart
// ✅ 올바른 import 경로
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/common/feature_button.dart';
```

---

## 📋 체크리스트

새 기능에 접근 제어를 추가할 때:

- [ ] 패턴 선택 (FeatureCard / FeatureButton / BlocBuilder)
- [ ] 레벨 선택 (emailVerified / careerVerified)
- [ ] Import 추가
- [ ] featureName 지정
- [ ] 테스트 (3개 레벨로 확인)
  - [ ] Level 0-1: 잠김 확인
  - [ ] Level 2: 상세 기능 잠김/해제 확인
  - [ ] Level 3: 모든 기능 해제 확인

---

## 🚀 다음 단계

이 가이드로 기본 구현을 완료했다면:

1. **Firestore Rules 업데이트** - `firestore.rules`에 `hasLoungeWriteAccess()` 함수 추가
2. **Cloud Functions 업데이트** - 직렬 인증 시 `careerTrackVerified: true` 설정
3. **네이밍 통일** - 앱 전체에서 "직렬 인증" 용어 사용

---

**마지막 업데이트:** 2024-10-11
**작성자:** Claude (Anthropic)
**문의:** AI-AGENT-GUIDE.md 관련 질문은 CLAUDE.md 참조
