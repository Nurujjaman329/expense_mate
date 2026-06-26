import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.amount,
    required super.period,
    super.categoryId,
    super.alertThreshold,
    super.alertEnabled,
    required super.startDate,
    super.endDate,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory BudgetModel.fromDrift(Budget row) {
    return BudgetModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      amount: row.amount,
      period: BudgetPeriod.values.byName(row.period),
      categoryId: row.categoryId,
      alertThreshold: row.alertThreshold,
      alertEnabled: row.alertEnabled,
      startDate: row.startDate,
      endDate: row.endDate,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory BudgetModel.fromFirestore(String id, Map<String, dynamic> json) {
    return BudgetModel(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.values.byName(json['period'] as String),
      categoryId: json['categoryId'] as String?,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      alertEnabled: json['alertEnabled'] as bool? ?? true,
      startDate: FirestoreMapper.parseDate(json['startDate']) ?? DateTime.now(),
      endDate: FirestoreMapper.parseDate(json['endDate']),
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      amount: entity.amount,
      period: entity.period,
      categoryId: entity.categoryId,
      alertThreshold: entity.alertThreshold,
      alertEnabled: entity.alertEnabled,
      startDate: entity.startDate,
      endDate: entity.endDate,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BudgetsCompanion toCompanion({bool isDeleted = false}) {
    return BudgetsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      amount: Value(amount),
      period: Value(period.name),
      categoryId: Value(categoryId),
      alertThreshold: Value(alertThreshold),
      alertEnabled: Value(alertEnabled),
      startDate: Value(startDate),
      endDate: Value(endDate),
      syncStatus: Value(syncStatus.name),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'name': name,
      'amount': amount,
      'period': period.name,
      'categoryId': categoryId,
      'alertThreshold': alertThreshold,
      'alertEnabled': alertEnabled,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
