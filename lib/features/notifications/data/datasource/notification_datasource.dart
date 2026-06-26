import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/notifications/data/models/notification_model.dart';

class NotificationLocalDataSource {
  NotificationLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _db.watchNotificationsByUser(userId).map(
          (rows) => rows.map(NotificationModel.fromDrift).toList(),
        );
  }

  Future<void> upsert(NotificationModel model) {
    return _db.upsertNotification(model.toCompanion());
  }

  Future<void> markAsRead(String id) {
    return _db.markNotificationRead(id);
  }

  Future<void> markAllAsRead(String userId) {
    return _db.markAllNotificationsRead(userId);
  }

  Future<void> enqueueSync(NotificationModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'notification',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }
}

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<NotificationModel>> fetchAll(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.notifications)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
