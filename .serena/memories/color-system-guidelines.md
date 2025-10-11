# GongMuTalk 색상 시스템 가이드라인

## 📌 중요 결정사항 (2025-01-XX)

**프로젝트 전체에서 색상 시스템 사용 원칙 정리**

## 🎨 두 가지 색상 시스템

### 1. `context.appColors` - Semantic Colors (커스텀 UI)
**언제 사용**: Semantic 의미가 명확한 커스텀 UI 컴포넌트

**사용 가능한 색상**:
- `success` / `successLight` / `successDark` - 성공, 재직연수, 정근수당 등
- `info` / `infoLight` / `infoDark` - 정보, 교육경력, 교원연구비 등
- `warning` / `warningLight` / `warningDark` - 경고, 중요, 퇴직 연령 등
- `error` / `errorLight` / `errorDark` - 오류, 실패
- `highlight` / `highlightLight` / `highlightDark` - 강조, 수정됨 배지 등
- `positive` / `negative` / `neutral` - 금융 관련 (증감, 중립)

**사용 예시**:
```dart
// 재직연수 카드 (초록 = 성공)
Container(
  decoration: BoxDecoration(
    color: context.appColors.successLight,  // 배경
    border: Border.all(color: context.appColors.success),  // 테두리
  ),
  child: Column(
    children: [
      Text('재직연수', style: TextStyle(color: context.appColors.successDark)),  // 타이틀
      Text('3년 7개월', style: TextStyle(color: context.appColors.successDark)),  // 숫자
      Text('정근수당 기준', style: TextStyle(color: context.appColors.success)),  // 설명
    ],
  ),
)
```

### 2. `Theme.of(context).colorScheme` - Material 3 Standards
**언제 사용**: Material 3 표준 컴포넌트가 사용하는 기본 색상

**사용 가능한 색상**:
- `surface` / `onSurface` - 기본 배경 및 텍스트
- `primary` / `onPrimary` - 주요 액션 버튼 등
- `outline` / `outlineVariant` - 테두리
- `onSurfaceVariant` - 보조 텍스트

**사용 예시**:
```dart
// Material 표준 컴포넌트
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
  ),
  child: Text('버튼'),
)

InputDecorator(
  decoration: InputDecoration(
    border: OutlineInputBorder(),
    labelText: '입력',
  ),
)
```

## ⚖️ 판단 기준

### ✅ `context.appColors` 사용 (Semantic)
1. **커스텀 카드/컨테이너**: 특정 의미를 전달하는 UI
2. **상태 표시**: 성공/실패/경고/정보를 나타내는 요소
3. **강조 요소**: 배지, 태그, 라벨 등
4. **금융 데이터**: positive/negative 표시

**예시**:
- ✅ 재직연수 카드 (초록 = 성공/완료)
- ✅ 교육경력 카드 (파란 = 정보)
- ✅ 퇴직 예정 연령 (노란 = 경고/중요)
- ✅ "수정됨" 배지 (오렌지 = 강조)
- ✅ 급여 증감 표시 (초록 = positive, 빨강 = negative)

### ❌ `Theme.of(context).colorScheme` 사용 (Material 3)
1. **Material 표준 위젯**: Button, Card, AppBar 등
2. **일반 텍스트**: 특별한 의미 없는 기본 텍스트
3. **기본 배경**: surface, background
4. **구조적 요소**: Divider, 기본 테두리

**예시**:
- ❌ ElevatedButton (Material 표준)
- ❌ InputDecorator 내부 텍스트 (일반)
- ❌ Scaffold background (구조)
- ❌ Divider (구조)

## 🚫 **절대 하지 말 것**

### ❌ 혼용 금지!
**같은 컴포넌트 내에서 두 시스템을 섞지 말 것**

```dart
// ❌ 나쁜 예시 (혼용)
Container(
  color: context.appColors.successLight,  // appColors 사용
  child: Text(
    '재직연수',
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),  // colorScheme 사용
  ),
)

// ✅ 좋은 예시 (통일)
Container(
  color: context.appColors.successLight,
  child: Text(
    '재직연수',
    style: TextStyle(color: context.appColors.successDark),  // 같은 시스템 사용
  ),
)
```

## 📝 실제 적용 사례

### Case 1: 재직연수 & 교육경력 카드 (quick_input_bottom_sheet.dart)
**변경 전** (혼용 ❌):
- 배경: `context.appColors.successLight` 
- 텍스트: `Theme.of(context).colorScheme.onSurface` ← 문제!

**변경 후** (통일 ✅):
- 배경: `context.appColors.successLight`
- 타이틀/숫자: `context.appColors.successDark`
- 설명: `context.appColors.success`

### Case 2: 퇴직 예정 연령 "중요" 배지
**변경 전**:
- 배경: `context.appColors.warningLight`
- 텍스트: `context.appColors.warning` ← 가독성 나쁨!

**변경 후**:
- 배경: `context.appColors.warningLight`
- 텍스트: `context.appColors.warningDark` ← 대비 개선!

## 💡 팁

### Light / Dark 조합 공식
밝은 배경에는 진한 텍스트:
- 배경 = `xxxLight` → 텍스트 = `xxxDark` or 기본 `xxx`
- 예: `successLight` + `successDark`

진한 배경에는 밝은 텍스트:
- 배경 = `xxxDark` → 텍스트 = `xxxLight`
- 예: `successDark` + `successLight`

## 🔍 체크리스트

새 UI를 만들 때:
1. [ ] 이 UI가 **특정 의미**(성공/경고/정보)를 전달하나? → `context.appColors`
2. [ ] Material 표준 위젯인가? → `Theme.of(context).colorScheme`
3. [ ] 같은 컴포넌트 내에서 **하나의 시스템만** 사용했나?
4. [ ] 배경과 텍스트 색상의 **대비**가 충분한가?

## 📚 참고 파일
- 색상 정의: `lib/core/theme/app_color_extension.dart`
- 실제 색상 값: `lib/core/constants/app_colors.dart`
- 적용 예시: `lib/features/calculator/presentation/widgets/quick_input_bottom_sheet.dart`
