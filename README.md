# 공무톡 (GongMuTalk)

<div align="center">
  
**대한민국 공무원을 위한 종합 자산 관리 및 커뮤니티 플랫폼**

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

[한국어](#한국어) | [English](#english)

</div>

---

## 한국어

### 📱 주요 기능

- **💰 급여 계산기**: 정확한 공무원 급여 계산 (호봉, 수당, 세금)
- **🏦 연금 계산기**: 퇴직 후 연금 예상액 계산
- **👥 직렬별 라운지**: 동일 직렬 공무원들의 정보 공유 커뮤니티
- **📄 직렬 인증**: OCR 기반 자동 직렬 인증 (급여명세서)
- **📊 급여 인사이트**: 교육공무원 급여 분석 (교사 전용)
- **📌 전보 정보**: 전보 관련 정보 공유
- **🔔 알림**: 중요 정보 실시간 푸시 알림

### 🚀 빠른 시작

#### 사전 요구사항
- Flutter SDK 3.8.1 이상
- Firebase CLI
- Node.js 22+ (Firebase Functions 개발 시)

#### 설치 및 실행
```bash
# 1. 저장소 클론
git clone [repository-url]
cd gong_mu_talk

# 2. 의존성 설치
flutter pub get

# 3. Firebase 설정 (필요시)
firebase use <your-project-id>

# 4. 앱 실행
flutter run
```

### 📚 문서

상세한 개발 가이드는 [CLAUDE.md](CLAUDE.md)를 참조하세요:
- 아키텍처 패턴
- 코딩 컨벤션
- 테스트 가이드라인
- Firebase 설정
- 성능 최적화

### 🏗 기술 스택

- **Frontend**: Flutter 3.8.1+
- **State Management**: BLoC/Cubit
- **Backend**: Firebase (Firestore, Functions, Storage, Auth)
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Dependency Injection**: GetIt (manual registration)
- **Routing**: GoRouter
- **Error Tracking**: Sentry, Firebase Crashlytics

### 🤝 기여

기여를 환영합니다! 자세한 내용은 [CLAUDE.md의 Contributing 섹션](CLAUDE.md#contributing)을 참조하세요.

### 📝 라이선스

This project is private and proprietary.

---

## English

### 📱 Key Features

- **💰 Salary Calculator**: Accurate public servant salary calculation (grade, allowances, taxes)
- **🏦 Pension Calculator**: Post-retirement pension estimation
- **👥 Career Lounges**: Community for public servants by career track
- **📄 Paystub Verification**: OCR-based automatic career track verification
- **📊 Salary Insights**: Salary analysis for educators (teachers only)
- **📌 Transfer Info**: Job transfer information sharing
- **🔔 Notifications**: Real-time push notifications

### 🚀 Quick Start

#### Prerequisites
- Flutter SDK 3.8.1+
- Firebase CLI
- Node.js 22+ (for Firebase Functions development)

#### Installation & Run
```bash
# 1. Clone repository
git clone [repository-url]
cd gong_mu_talk

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (if needed)
firebase use <your-project-id>

# 4. Run app
flutter run
```

### 📚 Documentation

For detailed development guide, see [CLAUDE.md](CLAUDE.md):
- Architecture patterns
- Coding conventions
- Testing guidelines
- Firebase setup
- Performance optimization

### 🏗 Tech Stack

- **Frontend**: Flutter 3.8.1+
- **State Management**: BLoC/Cubit
- **Backend**: Firebase (Firestore, Functions, Storage, Auth)
- **Architecture**: Clean Architecture (Domain/Data/Presentation)
- **Dependency Injection**: GetIt (manual registration)
- **Routing**: GoRouter
- **Error Tracking**: Sentry, Firebase Crashlytics

### 🤝 Contributing

Contributions are welcome! See [Contributing section in CLAUDE.md](CLAUDE.md#contributing) for details.

### 📝 License

This project is private and proprietary.
