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