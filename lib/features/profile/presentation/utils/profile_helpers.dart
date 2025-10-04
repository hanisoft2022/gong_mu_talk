/// Helper functions for profile-related UI components.
///
/// This file contains utility functions used across profile views and widgets.
library;

/// Formats a [DateTime] into a human-readable relative time string.
///
/// Examples:
/// - Less than 1 minute ago: '방금'
/// - 5 minutes ago: '5분 전'
/// - 2 hours ago: '2시간 전'
/// - 3 days ago: '3일 전'
/// - More than 7 days: '2024.01.15'
String formatDateRelative(DateTime dateTime) {
  final DateTime now = DateTime.now();
  final Duration difference = now.difference(dateTime);

  if (difference.inMinutes.abs() < 1) {
    return '방금';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  }

  return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
}
