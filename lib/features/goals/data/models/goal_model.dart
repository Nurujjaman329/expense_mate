import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';

class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.targetAmount,
    super.currentAmount,
    super.targetDate,
    super.icon,
    super.color,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory GoalModel.fromDrift(Goal row) {
    return GoalModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: GoalType.values.byName(row.type),
      targetAmount: row.targetAmount,
      currentAmount: row.currentAmount,
      targetDate: row.targetDate,
      icon: row.icon,
      color: row.color,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory GoalModel.fromFirestore(String id, Map<String, dynamic> json) {
    return GoalModel(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: GoalType.values.byName(json['type'] as String),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      targetDate: FirestoreMapper.parseDate(json['targetDate']),
      icon: json['icon'] as String?,
      color: json['color'] as int?,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  factory GoalModel.fromEntity(GoalEntity entity) {
    return GoalModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      targetAmount: entity.targetAmount,
      currentAmount: entity.currentAmount,
      targetDate: entity.targetDate,
      icon: entity.icon,
      color: entity.color,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  GoalsCompanion toCompanion({bool isDeleted = false}) {
    return GoalsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type.name),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      targetDate: Value(targetDate),
      icon: Value(icon),
      color: Value(color),
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
      'type': type.name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'icon': icon,
      'color': color,
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SavingModel extends SavingEntity {
  const SavingModel({
    required super.id,
    required super.userId,
    super.goalId,
    required super.name,
    required super.amount,
    super.currency,
    super.note,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory SavingModel.fromDrift(Saving row) {
    return SavingModel(
      id: row.id,
      userId: row.userId,
      goalId: row.goalId,
      name: row.name,
      amount: row.amount,
      currency: row.currency,
      note: row.note,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory SavingModel.fromFirestore(String id, Map<String, dynamic> json) {
    return SavingModel(
      id: id,
      userId: json['userId'] as String,
      goalId: json['goalId'] as String?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      note: json['note'] as String?,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  SavingsCompanion toCompanion({bool isDeleted = false}) {
    return SavingsCompanion(
      id: Value(id),
      userId: Value(userId),
      goalId: Value(goalId),
      name: Value(name),
      amount: Value(amount),
      currency: Value(currency),
      note: Value(note),
      syncStatus: Value(syncStatus.name),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'goalId': goalId,
      'name': name,
      'amount': amount,
      'currency': currency,
      'note': note,
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
