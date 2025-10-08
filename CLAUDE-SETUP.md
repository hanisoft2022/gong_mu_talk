# CLAUDE-SETUP.md

**Development Setup & Troubleshooting Guide for GongMuTalk**

This document covers development environment setup, workflows, Firebase integration, and common troubleshooting steps.

> 💡 **When to read this**: When setting up the project for the first time, configuring Firebase, or encountering build/runtime issues.

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

---

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

---

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

---

**Related Documents**:
- [CLAUDE.md](CLAUDE.md) - Main overview and principles
- [CLAUDE-ARCHITECTURE.md](CLAUDE-ARCHITECTURE.md) - Architecture details
- [CLAUDE-PATTERNS.md](CLAUDE-PATTERNS.md) - Common patterns and Git workflow
