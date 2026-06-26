import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.amount,
    super.categoryId,
    super.walletId,
    required super.dueDate,
    super.isRecurring,
    super.recurringRule,
    super.isPaid,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory BillModel.fromDrift(Bill row) {
    return BillModel(
      id: row.id,
      userId: row.userId,
      title: row.title,
      amount: row.amount,
      categoryId: row.categoryId,
      walletId: row.walletId,
      dueDate: row.dueDate,
      isRecurring: row.isRecurring,
      recurringRule: row.recurringRule != null
          ? RecurringRule.values.byName(row.recurringRule!)
          : null,
      isPaid: row.isPaid,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory BillModel.fromFirestore(String id, Map<String, dynamic> json) {
    return BillModel(
      id: id,
      userId: json['userId'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String?,
      walletId: json['walletId'] as String?,
      dueDate: FirestoreMapper.parseDate(json['dueDate']) ?? DateTime.now(),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringRule: json['recurringRule'] != null
          ? RecurringRule.values.byName(json['recurringRule'] as String)
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  factory BillModel.fromEntity(BillEntity entity) {
    return BillModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      amount: entity.amount,
      categoryId: entity.categoryId,
      walletId: entity.walletId,
      dueDate: entity.dueDate,
      isRecurring: entity.isRecurring,
      recurringRule: entity.recurringRule,
      isPaid: entity.isPaid,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BillsCompanion toCompanion({bool isDeleted = false}) {
    return BillsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      amount: Value(amount),
      categoryId: Value(categoryId),
      walletId: Value(walletId),
      dueDate: Value(dueDate),
      isRecurring: Value(isRecurring),
      recurringRule: Value(recurringRule?.name),
      isPaid: Value(isPaid),
      syncStatus: Value(syncStatus.name),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'walletId': walletId,
      'dueDate': dueDate.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringRule': recurringRule?.name,
      'isPaid': isPaid,
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
