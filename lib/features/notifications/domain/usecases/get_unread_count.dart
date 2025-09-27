import '../../../../core/utils/result.dart';
import '../repositories/i_notification_repository.dart';

class GetUnreadCount {
  const GetUnreadCount(this._repository);

  final INotificationRepository _repository;

  Future<AppResult<int>> call() async {
    return _repository.getUnreadCount();
  }
}