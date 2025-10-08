part of 'notification_preferences_cubit.dart';

/// Notification preferences state
class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.likeNotifications = true,
    this.commentNotifications = true,
    this.followNotifications = true,
    this.isLoading = false,
  });

  final bool likeNotifications;
  final bool commentNotifications;
  final bool followNotifications;
  final bool isLoading;

  @override
  List<Object?> get props => [
    likeNotifications,
    commentNotifications,
    followNotifications,
    isLoading,
  ];

  NotificationPreferencesState copyWith({
    bool? likeNotifications,
    bool? commentNotifications,
    bool? followNotifications,
    bool? isLoading,
  }) {
    return NotificationPreferencesState(
      likeNotifications: likeNotifications ?? this.likeNotifications,
      commentNotifications: commentNotifications ?? this.commentNotifications,
      followNotifications: followNotifications ?? this.followNotifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
