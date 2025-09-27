import '../../../../core/utils/result.dart';
import '../entities/notification.dart';
import '../repositories/i_notification_repository.dart';

class GetNotifications {
  const GetNotifications(this._repository);

  final INotificationRepository _repository;

  Future<AppResult<List<AppNotification>>> call({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    return _repository.getNotifications(
      limit: limit,
      lastDocumentId: lastDocumentId,
    );
  }
}