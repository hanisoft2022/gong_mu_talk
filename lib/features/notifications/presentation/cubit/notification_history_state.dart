import 'package:equatable/equatable.dart';

import '../../domain/entities/notification.dart';

class NotificationHistoryState extends Equatable {
  const NotificationHistoryState({
    this.notifications = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  NotificationHistoryState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return NotificationHistoryState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        isLoading,
        hasError,
        errorMessage,
      ];
}
