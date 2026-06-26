import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/notifications/data/datasource/notification_datasource.dart';
import 'package:expense_mate/features/notifications/data/models/notification_model.dart';
import 'package:expense_mate/features/notifications/domain/entities/notification_entity.dart';
import 'package:expense_mate/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationLocalDataSource local,
    required NotificationRemoteDataSource remote,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final NotificationLocalDataSource _local;
  final NotificationRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;

  Future<void> _save(NotificationModel model, String operation) async {
    await _local.upsert(model);
    await _local.enqueueSync(model, operation);
    if (await _networkInfo.isConnected) await _syncEngine.syncAll();
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _local.watchNotifications(userId).map((list) => list);
  }

  @override
  Future<Result<NotificationEntity>> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      final model = NotificationModel.fromEntity(notification).copyWithPending();
      await _save(model, 'create');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    try {
      await _local.markAsRead(id);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _local.markAllAsRead(userId);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncFromRemote(String userId) async {
    try {
      if (!await _networkInfo.isConnected) return const Success(null);
      final remote = await _remote.fetchAll(userId);
      for (final item in remote) {
        await _local.upsert(
          NotificationModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            body: item.body,
            type: item.type,
            isRead: item.isRead,
            payload: item.payload,
            syncStatus: SyncStatus.synced,
            createdAt: item.createdAt,
          ),
        );
      }
      await _syncEngine.syncAll();
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}

extension on NotificationModel {
  NotificationModel copyWithPending() {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead,
      payload: payload,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

final notificationLocalDataSourceProvider =
    Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource(ref.watch(appDatabaseProvider));
});

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(firestoreProvider));
});

final notificationRepositoryImplProvider =
    Provider<NotificationRepositoryImpl>((ref) {
  return NotificationRepositoryImpl(
    local: ref.watch(notificationLocalDataSourceProvider),
    remote: ref.watch(notificationRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ref.watch(notificationRepositoryImplProvider);
});

final notificationsStreamProvider =
    StreamProvider.family<List<NotificationEntity>, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(userId);
});

final unreadNotificationCountProvider =
    Provider.family<int, String>((ref, userId) {
  final notifications =
      ref.watch(notificationsStreamProvider(userId)).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
