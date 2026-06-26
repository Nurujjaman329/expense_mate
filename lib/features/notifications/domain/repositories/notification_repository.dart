import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> watchNotifications(String userId);

  Future<Result<NotificationEntity>> createNotification(
    NotificationEntity notification,
  );

  Future<Result<void>> markAsRead(String id);

  Future<Result<void>> markAllAsRead(String userId);

  Future<Result<void>> syncFromRemote(String userId);
}
