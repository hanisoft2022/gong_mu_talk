import 'package:flutter/material.dart';

/// 스크랩 상태 변경 시 보여주는 공통 스낵바
/// 스크랩 추가/해제 메시지와 실행 취소 기능 제공
void showScrapUndoSnackBar({
  required BuildContext context,
  required bool wasAdded,
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(wasAdded ? '스크랩이 완료되었습니다.' : '스크랩이 해제되었습니다.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: '실행 취소', textColor: Colors.yellow, onPressed: onUndo),
      ),
    );
}
