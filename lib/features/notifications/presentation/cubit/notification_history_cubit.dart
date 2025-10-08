import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/notification_repository.dart';
import '../../domain/entities/notification.dart';
import 'notification_history_state.dart';

class NotificationHistoryCubit extends Cubit<NotificationHistoryState> {
  NotificationHistoryCubit(this._repository)
      : super(const NotificationHistoryState());

  final NotificationRepository _repository;

  Future<void> loadNotifications(String userId) async {
    if (userId.isEmpty) {
      emit(const NotificationHistoryState());
      return;
    }

    emit(state.copyWith(isLoading: true, hasError: false, errorMessage: null));

    try {
      final notifications = await _repository.getAllNotifications(userId);

      emit(
        NotificationHistoryState(
          notifications: notifications,
          isLoading: false,
          hasError: false,
        ),
      );
    } catch (error) {
      emit(
        NotificationHistoryState(
          notifications: const [],
          isLoading: false,
          hasError: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> markAsRead(String userId, AppNotification notification) async {
    if (notification.isRead || userId.isEmpty) return;

    try {
      await _repository.markAsRead(userId, notification.id);

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notification.id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      emit(state.copyWith(notifications: updatedNotifications));
    } catch (error) {
      // Silently fail - not critical
    }
  }

  Future<void> deleteNotification(
    String userId,
    AppNotification notification,
  ) async {
    if (userId.isEmpty) return;

    try {
      await _repository.deleteNotification(userId, notification.id);

      // Update local state
      final updatedNotifications = state.notifications
          .where((n) => n.id != notification.id)
          .toList();

      emit(state.copyWith(notifications: updatedNotifications));
    } catch (error) {
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;

    try {
      await _repository.markAllAsRead(userId);

      // Update local state
      final updatedNotifications = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      emit(state.copyWith(notifications: updatedNotifications));
    } catch (error) {
      rethrow;
    }
  }
}
