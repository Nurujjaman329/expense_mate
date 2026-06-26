import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

/// Domain entity for savings goals.
class GoalEntity extends Equatable {
  const GoalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.icon,
    this.color,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? icon;
  final int? color;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  bool get isCompleted => currentAmount >= targetAmount;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        targetAmount,
        currentAmount,
        targetDate,
        icon,
        color,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}

/// Savings contribution linked to a goal.
class SavingEntity extends Equatable {
  const SavingEntity({
    required this.id,
    required this.userId,
    this.goalId,
    required this.name,
    required this.amount,
    this.currency = 'USD',
    this.note,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? goalId;
  final String name;
  final double amount;
  final String currency;
  final String? note;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        goalId,
        name,
        amount,
        currency,
        note,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}
