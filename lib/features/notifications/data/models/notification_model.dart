import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.isRead,
    super.payload,
    super.syncStatus,
    super.createdAt,
  });

  factory NotificationModel.fromDrift(Notification row) {
    return NotificationModel(
      id: row.id,
      userId: row.userId,
      title: row.title,
      body: row.body,
      type: NotificationType.values.byName(row.type),
      isRead: row.isRead,
      payload: row.payload,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
    );
  }

  factory NotificationModel.fromFirestore(String id, Map<String, dynamic> json) {
    return NotificationModel(
      id: id,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.byName(json['type'] as String),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as String?,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
    );
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      isRead: entity.isRead,
      payload: entity.payload,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
    );
  }

  NotificationsCompanion toCompanion() {
    return NotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      body: Value(body),
      type: Value(type.name),
      isRead: Value(isRead),
      payload: Value(payload),
      syncStatus: Value(syncStatus.name),
      createdAt: Value(createdAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'payload': payload,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
