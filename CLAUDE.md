# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GongMuTalk (공무톡) is a Flutter-based comprehensive asset management and community platform for public servants in Korea. The app provides salary/pension calculators, community features, professional matching, and life management tools.

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run code generation for freezed, json_serializable, etc.
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Analyze code
flutter analyze

# Format code
dart format lib test

# Run tests
flutter test

# Run a specific test file
flutter test test/path/to/test_file.dart

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

### Firebase Commands
```bash
# Deploy to Firebase (requires Firebase CLI)
firebase deploy

# Deploy only hosting
firebase deploy --only hosting

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
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
Each feature module follows clean architecture:
```
features/[feature_name]/
├── domain/          # Business logic and entities
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/            # Data layer implementations
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/    # UI layer
    ├── bloc/        # BLoC pattern state management
    ├── cubit/       # Cubit state management
    ├── views/       # Pages/screens
    └── widgets/     # Feature-specific widgets
```

### Key Features
- **auth**: Firebase authentication with Google/Kakao sign-in
- **calculator**: Salary calculator for public servants
- **community**: Social feed, posts, comments, likes
- **profile**: User profiles and verification
- **matching**: Professional matching service
- **life**: Life management and meetings
- **pension**: Pension calculator
- **monetization**: Premium features and payments (Bootpay integration)
- **notifications**: Push notifications via Firebase

### State Management
- BLoC/Cubit pattern using flutter_bloc
- GetIt for dependency injection
- GoRouter for navigation with authentication guards

### Key Dependencies
- **Firebase**: Core, Auth, Firestore, Storage, Messaging, Crashlytics
- **State Management**: flutter_bloc, bloc_concurrency
- **Navigation**: go_router
- **Code Generation**: freezed, json_serializable, build_runner
- **UI**: google_fonts, lottie, rive, skeletonizer, fl_chart
- **Payments**: bootpay
- **Social Login**: google_sign_in, kakao_flutter_sdk_user

## Firebase Configuration
- Firestore is the primary database
- Firebase Auth handles user authentication
- Firebase Storage for file uploads
- Firebase Messaging for push notifications
- Indexes defined in `firestore.indexes.json`

## Testing Strategy
- Unit tests for business logic (usecases, repositories)
- Widget tests for UI components
- BLoC tests using bloc_test
- Mock dependencies using mocktail

## Code Generation
The project uses several code generation tools. Always run after modifying:
- Models with `@freezed` or `@JsonSerializable` annotations
- Injectable services with `@injectable` annotations
- GoRouter routes with `@TypedGoRoute` annotations

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

## Important Conventions
- Follow Material 3 design guidelines
- Use BLoC/Cubit for complex state management
- Implement repository pattern for data access
- Keep Firebase logic isolated in data layer
- Use dependency injection via GetIt
- Prefer const constructors for performance
- Handle errors gracefully with proper user feedback

## 파일 크기 및 구조 관리 원칙

### 핵심 철학
**"파일 크기보다 단일 책임이 중요하다"**

파일 타입별로 다른 크기 기준을 적용하여 AI 토큰 사용을 최적화하면서도 실용적인 코드 구조를 유지합니다.

### 파일 타입별 크기 가이드라인

#### UI 파일 (views/, widgets/)
```
✅ Green Zone:  0-400줄   (이상적)
⚠️ Yellow Zone: 400-600줄 (검토 권장)
🔶 Orange Zone: 600-800줄 (리팩토링 권장)
🚨 Red Zone:    800줄+    (즉시 리팩토링 필수)
```
- UI는 Flutter 특성상 길어지기 쉬움을 고려
- 400줄 = 약 4,000 토큰 (AI가 읽기 적당한 크기)

#### 로직 파일 (cubit/, bloc/, repositories/, usecases/)
```
✅ Green Zone:  0-300줄   (이상적)
⚠️ Yellow Zone: 300-500줄 (검토 권장)
🔶 Orange Zone: 500-700줄 (리팩토링 권장)
🚨 Red Zone:    700줄+    (즉시 리팩토링 필수)
```
- 로직은 더 작게 유지하여 단일 책임 원칙 엄격히 적용
- 테스트 용이성 확보

#### 도메인 파일 (entities/, models/, constants/)
```
✅ Green Zone:  0-200줄   (이상적)
⚠️ Yellow Zone: 200-400줄 (검토 권장)
🔶 Orange Zone: 400-600줄 (리팩토링 권장)
🚨 Red Zone:    600줄+    (즉시 리팩토링 필수)
```
- 데이터 모델과 상수는 간결해야 함
- 복잡하면 설계 재검토 필요

#### 유틸리티/헬퍼 (utils/, helpers/)
```
✅ Green Zone:  0-250줄   (이상적)
⚠️ Yellow Zone: 250-400줄 (검토 권장)
🔶 Orange Zone: 400-600줄 (리팩토링 권장)
🚨 Red Zone:    600줄+    (즉시 리팩토링 필수)
```

### 분리 기준 (우선순위 순)

#### 1순위: 단일 책임 원칙
```dart
// ❌ 여러 책임 섞임
class ProfilePage {
  // 프로필 표시 + 편집 + 설정 + 통계 + 알림
  // → 각각 분리 필요!
}

// ✅ 단일 책임
class ProfilePage {
  // 프로필 표시만
}
class ProfileEditPage { }
class ProfileSettingsPage { }
```

#### 2순위: 위젯/클래스 수
- **Private 위젯 5개 이상**: 즉시 분리
- **Private 위젯 3-4개**: 분리 고려
- **Public 클래스 2개 이상**: 별도 파일로 분리

#### 3순위: 상수 및 헬퍼
- **상수 10개 이상**: `constants/` 디렉토리로 분리
- **헬퍼 함수 3개 이상**: `utils/` 디렉토리로 분리

### 권장 파일 구조

```
feature/
├── presentation/
│   ├── views/
│   │   └── feature_page.dart        (300-400줄, 레이아웃 조립)
│   ├── widgets/
│   │   ├── feature_header.dart      (200-400줄)
│   │   ├── feature_content.dart     (200-400줄)
│   │   └── sections/
│   │       ├── section_a.dart       (200-350줄)
│   │       └── section_b.dart       (200-350줄)
│   ├── utils/
│   │   └── feature_helpers.dart     (100-250줄)
│   └── cubit/
│       ├── feature_cubit.dart       (200-300줄)
│       └── feature_state.dart       (100-200줄)
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart      (100-200줄)
│   ├── constants/
│   │   └── feature_constants.dart   (50-200줄)
│   └── usecases/
│       └── feature_usecase.dart     (100-300줄)
└── data/
    ├── repositories/
    │   └── feature_repository.dart  (200-400줄)
    └── models/
        └── feature_model.dart       (100-200줄)
```

### 예외 허용 케이스

다음 경우는 해당 타입 기준보다 더 큰 파일 허용 (최대 +200줄):

1. **복잡한 State 클래스** (StatefulWidget의 State)
2. **핵심 계산 알고리즘** (급여 계산, 연금 계산 등)
3. **복잡한 폼 로직** (다단계 유효성 검사 포함)

조건:
- 정말로 단일 책임만 가짐
- 주석으로 섹션을 명확히 구분
- 파일 상단에 예외 사유 명시

### 코드 작성 시 자가 점검

새 파일 작성 또는 수정 시 체크리스트:

```
1. 파일 타입 확인 (UI/로직/도메인/유틸)
2. 해당 타입의 Green Zone 내인가?
3. 주요 책임이 1개인가?
4. Private 위젯이 5개 미만인가?
5. 상수가 10개 미만인가?
6. Yellow Zone 이상이면:
   → 분리 가능한 부분 찾기
   → 단일 책임 확인
   → 필요시 리팩토링
```

### 리팩토링 판단 플로우

```
파일 발견 시:
├─ Red Zone (즉시 리팩토링)
│  ├─ UI: 800줄+
│  ├─ 로직: 700줄+
│  ├─ 도메인: 600줄+
│  └─ 유틸: 600줄+
│
├─ Orange Zone (리팩토링 강력 권장)
│  └─ 여러 책임 섞임? → 즉시 분리
│  └─ Private 위젯 5개+? → 즉시 분리
│  └─ 단일 책임? → 검토 후 결정
│
├─ Yellow Zone (검토 권장)
│  └─ 여러 책임? → 분리
│  └─ Private 위젯 3-4개? → 분리 고려
│  └─ 단일 책임? → 유지 OK
│
└─ Green Zone (유지 OK)
```

### 측정 도구

```bash
# 파일 타입별 큰 파일 찾기
# UI 파일 (400줄 이상)
find lib/features/*/presentation/{views,widgets} -name "*.dart" -exec wc -l {} + | awk '$1 > 400' | sort -rn

# 로직 파일 (300줄 이상)
find lib/features/*/presentation/{cubit,bloc} lib/features/*/data/repositories -name "*.dart" -exec wc -l {} + | awk '$1 > 300' | sort -rn

# 도메인 파일 (200줄 이상)
find lib/features/*/domain -name "*.dart" -exec wc -l {} + | awk '$1 > 200' | sort -rn

# Red Zone 파일 찾기 (즉시 리팩토링 필요)
find lib -name "*.dart" -exec wc -l {} + | awk '$1 > 800' | sort -rn
```

### 목표 지표

- **평균 파일 크기**: 250-350줄
- **AI 분석 시 평균 토큰**: 2,500-3,500 토큰/파일
- **Red Zone 파일**: 0개
- **Orange Zone 파일**: 전체의 5% 이하

## Git 커밋 규칙
- feat: 새로운 기능 추가
- fix: 버그 수정
- docs: 문서 수정
- style: 코드 포매팅 (기능 변경 없음)
- refactor: 코드 리팩토링 (기능 변경 없음)
- test: 테스트 추가 또는 수정
- chore: 빌드 프로세스 또는 보조 도구 변경

## 커밋 메시지 형식
```
<type>(<scope>): <subject>
```

### 예시
```
feat(auth): 소셜 로그인 기능 추가
fix(api): 사용자 조회 시 null 참조 오류 수정
```