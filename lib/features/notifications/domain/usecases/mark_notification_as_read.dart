import '../../../../core/utils/result.dart';
import '../repositories/i_notification_repository.dart';

class MarkNotificationAsRead {
  const MarkNotificationAsRead(this._repository);

  final INotificationRepository _repository;

  Future<AppResult<void>> call(String notificationId) async {
    return _repository.markAsRead(notificationId);
  }
}