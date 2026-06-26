import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

/// Domain entity for spending budgets.
class BudgetEntity extends Equatable {
  const BudgetEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.period,
    this.categoryId,
    this.alertThreshold = 0.8,
    this.alertEnabled = true,
    required this.startDate,
    this.endDate,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final double amount;
  final BudgetPeriod period;
  final String? categoryId;
  final double alertThreshold;
  final bool alertEnabled;
  final DateTime startDate;
  final DateTime? endDate;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        amount,
        period,
        categoryId,
        alertThreshold,
        alertEnabled,
        startDate,
        endDate,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}

/// Budget with computed spending progress.
class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOverBudget,
    required this.isAlertTriggered,
  });

  final BudgetEntity budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOverBudget;
  final bool isAlertTriggered;

  @override
  List<Object?> get props => [
        budget,
        spent,
        remaining,
        percentage,
        isOverBudget,
        isAlertTriggered,
      ];
}
