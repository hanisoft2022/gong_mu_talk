/// DateTime 관련 유틸리티 함수들
class DateTimeHelpers {
  DateTimeHelpers._();

  /// 상대적 시간 표시 (방금 전, 1분 전, 1시간 전 등)
  static String getRelativeTime(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}월 ${dateTime.day}일';
    }
  }

  /// 포맷된 날짜 문자열 반환
  static String formatDate(DateTime dateTime, {String format = 'yyyy-MM-dd'}) {
    switch (format) {
      case 'yyyy-MM-dd':
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      case 'MM월 dd일':
        return '${dateTime.month}월 ${dateTime.day}일';
      case 'yyyy년 MM월 dd일':
        return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
      default:
        return dateTime.toString();
    }
  }

  /// 시간 포맷
  static String formatTime(DateTime dateTime, {bool use24Hour = false}) {
    if (use24Hour) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      final int hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
      final String period = dateTime.hour < 12 ? '오전' : '오후';
      return '$period $hour:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 오늘인지 확인
  static bool isToday(DateTime dateTime) {
    final DateTime now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// 어제인지 확인
  static bool isYesterday(DateTime dateTime) {
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }
}

/// DateTime 확장 메서드들
extension DateTimeExtensions on DateTime {
  /// 상대적 시간 표시
  String get relativeTime => DateTimeHelpers.getRelativeTime(this);

  /// 오늘인지 확인
  bool get isToday => DateTimeHelpers.isToday(this);

  /// 어제인지 확인
  bool get isYesterday => DateTimeHelpers.isYesterday(this);

  /// 포맷된 날짜 문자열
  String format([String format = 'yyyy-MM-dd']) => DateTimeHelpers.formatDate(this, format: format);

  /// 포맷된 시간 문자열
  String formatTime({bool use24Hour = false}) => DateTimeHelpers.formatTime(this, use24Hour: use24Hour);
}