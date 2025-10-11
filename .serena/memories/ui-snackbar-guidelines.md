# Snackbar 사용 가이드라인

## 필수 규칙
**항상 `SnackbarHelpers`를 사용할 것** - 직접 ScaffoldMessenger를 사용하지 말 것

## SnackbarHelpers 메서드 선택 가이드

### 1. `showSuccess()` - 초록색 + 체크 아이콘
**사용 시기**: 사용자 액션이 성공적으로 완료됨
- 로그아웃 완료
- 저장 완료
- 설정 변경 완료
- 게시물 작성 완료
- 인증 완료

**예시**:
```dart
SnackbarHelpers.showSuccess(context, '로그아웃 되었습니다.');
SnackbarHelpers.showSuccess(context, '프로필이 업데이트되었습니다.');
```

### 2. `showInfo()` - 파란색 + info 아이콘
**사용 시기**: 중립적인 정보성 알림
- 신고 접수됨
- 게시물 등록됨 (성공보다는 정보 전달에 가까운 경우)
- 시스템 알림

**예시**:
```dart
SnackbarHelpers.showInfo(context, '신고가 접수되었습니다.');
```

### 3. `showError()` - 빨간색 + error 아이콘
**사용 시기**: 작업 실패 또는 에러
- 저장 실패
- 네트워크 오류
- API 호출 실패
- 유효성 검증 실패 (심각한 경우)

**예시**:
```dart
SnackbarHelpers.showError(context, '저장에 실패했습니다.');
SnackbarHelpers.showError(context, '네트워크 오류가 발생했습니다.');
```

### 4. `showWarning()` - 주황색 + warning 아이콘
**사용 시기**: 경고 또는 주의사항
- 필수 입력 항목 누락
- 권한 필요
- 제한사항 알림
- 유효성 검증 실패 (가벼운 경우)

**예시**:
```dart
SnackbarHelpers.showWarning(context, '필수 입력 항목입니다.');
SnackbarHelpers.showWarning(context, '카메라 권한이 필요합니다.');
```

### 5. `showUndo()` - 실행 취소 기능 포함
**사용 시기**: 되돌릴 수 있는 작업
- 삭제
- 차단
- 스크랩
- 좋아요 취소

**예시**:
```dart
SnackbarHelpers.showUndo(
  context,
  message: '게시물을 스크랩했습니다',
  onUndo: () => _repository.undoScrap(),
);
```

## 선택 기준 우선순위

1. **작업이 되돌릴 수 있나?** → `showUndo()`
2. **작업이 실패했나?** → `showError()`
3. **사용자가 주의해야 하나?** → `showWarning()`
4. **작업이 성공했나?** → `showSuccess()`
5. **정보만 전달하나?** → `showInfo()`

## 일반적인 사용 사례

| 상황 | 메서드 | 메시지 예시 |
|------|--------|-------------|
| 로그아웃 | showSuccess | '로그아웃 되었습니다.' |
| 로그인 | showSuccess | '로그인 되었습니다.' |
| 프로필 수정 | showSuccess | '프로필이 업데이트되었습니다.' |
| 게시물 작성 | showSuccess | '게시물이 등록되었습니다.' |
| 게시물 삭제 | showUndo | '게시물을 삭제했습니다' + 실행 취소 |
| 신고 접수 | showInfo | '신고가 접수되었습니다.' |
| API 오류 | showError | '일시적인 오류가 발생했습니다.' |
| 필수 입력 누락 | showWarning | '닉네임을 입력해주세요.' |
| 권한 필요 | showWarning | '사진 접근 권한이 필요합니다.' |

## 참고 사항

- Duration은 메서드가 자동으로 결정 (showError, showWarning은 조금 더 길게 표시)
- 필요시 `duration` 파라미터로 커스터마이즈 가능
- Material 3 디자인 가이드 기반으로 일관된 UI 제공
- Floating 스타일 + 둥근 모서리로 현대적인 느낌
