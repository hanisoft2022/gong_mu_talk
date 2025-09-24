# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Gong Mu Talk** (공무톡) is a comprehensive Flutter application for Korean civil servants providing asset management and community platform features. The app is written in Korean and targets civil service employees.

## Key Technologies & Architecture

- **Flutter 3.8.1+** with Dart
- **State Management**: Flutter Bloc (BLoC pattern) with Cubit
- **Navigation**: go_router with authentication-based routing
- **Dependency Injection**: get_it + injectable with code generation
- **Backend**: Firebase (Firestore, Auth, Storage, Crashlytics, Functions)
- **Authentication**: Google Sign-In + Kakao Flutter SDK
- **Code Generation**: build_runner, freezed, json_serializable, retrofit_generator
- **UI**: Material Design with custom theming, Google Fonts, Lottie animations

## Development Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Generate code (models, DI, routing)
dart run build_runner build

# Run code generation in watch mode
dart run build_runner watch

# Run the app
flutter run

# Run tests
flutter test

# Clean build artifacts
flutter clean

# Build for release
flutter build apk
flutter build ios
```

### Firebase Functions
```bash
# Navigate to functions directory first
cd functions

# Install dependencies
npm install

# Lint TypeScript code
npm run lint

# Build TypeScript to JavaScript
npm run build

# Run Firebase emulators (functions only)
npm run serve

# Deploy functions to Firebase
npm run deploy
```

### Firebase Emulators
```bash
# Start all Firebase emulators (from project root)
firebase emulators:start

# Emulator ports:
# - Auth: 9099
# - Firestore: 8080
# - Functions: 5001
# - Storage: 9199
# - UI: localhost:4000
```

## Architecture Patterns

### Feature-Based Structure
The codebase follows a feature-based architecture with clean architecture principles:

```
lib/features/[feature_name]/
├── data/           # Repository implementations, data sources
├── domain/         # Entities, repositories interfaces
└── presentation/   # UI (Cubit, Views, Widgets)
    ├── cubit/     # BLoC state management
    ├── views/     # Page-level widgets
    └── widgets/   # Reusable UI components
```

### Key Features
- **community**: Post creation, feed browsing, likes/comments system
- **blind**: Anonymous posting and community features
- **matching**: User matching and connection system
- **calculator**: Salary and pension calculation tools
- **profile**: User profile management
- **auth**: Authentication and user management
- **payments**: Bootpay integration for payment processing

### State Management Pattern
- Uses **Cubit** (simplified BLoC) for state management
- State classes typically use **freezed** for immutability
- Repository pattern with Firebase Firestore integration
- Dependency injection configured in `lib/di/di.dart`

### Navigation & Routing
- **go_router** with authentication-based redirects
- Shell routing with bottom navigation (AppShell)
- Route definitions in `lib/routing/app_router.dart`
- Authentication state determines accessible routes

### Firebase Integration
- **Firestore**: Document/collection-based data storage
- **Authentication**: Google + Kakao social login
- **Cloud Functions**: Backend logic (Node.js/TypeScript)
- **Storage**: Image and file uploads
- **Crashlytics**: Error tracking and reporting

## Code Generation

The project heavily relies on code generation. Always run after modifying:
- Models with `@freezed` or `@JsonSerializable`
- Injectable dependencies with `@injectable`
- Repository interfaces with `@RestApi`

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Testing

- Tests located in `test/` directory
- Uses `flutter_test`, `bloc_test`, and `mocktail`
- Focus on model serialization roundtrip tests
- Run tests with: `flutter test`

## Firebase Configuration

- Project ID: `gong-mu-talk`
- Firestore location: `asia-northeast3`
- Supports both Android and iOS platforms
- Functions written in TypeScript (Node.js 22)

## Important Files

- `lib/main.dart`: App entry point
- `lib/bootstrap/bootstrap.dart`: App initialization and setup
- `lib/di/di.dart`: Dependency injection configuration
- `lib/routing/app_router.dart`: Navigation and routing logic
- `pubspec.yaml`: Dependencies and app configuration
- `firebase.json`: Firebase project configuration
- `analysis_options.yaml`: Dart/Flutter linting rules

## Development Notes

- Korean language support (`ko` locale)
- Custom app theme with light/dark mode support
- Shorebird code push integration for over-the-air updates
- Google Mobile Ads integration
- Image picker and cached network images
- Material Design with custom color schemes