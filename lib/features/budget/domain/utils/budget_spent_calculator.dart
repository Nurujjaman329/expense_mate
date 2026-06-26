import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';

/// Computes budget spent amounts and period date ranges from transactions.
class BudgetSpentCalculator {
  BudgetSpentCalculator._();

  static ({DateTime start, DateTime end}) periodRange(
    BudgetPeriod period, {
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    switch (period) {
      case BudgetPeriod.daily:
        return (start: DateTime(now.year, now.month, now.day), end: now);
      case BudgetPeriod.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(start.year, start.month, start.day),
          end: start.add(const Duration(days: 6, hours: 23, minutes: 59)),
        );
      case BudgetPeriod.monthly:
        return (
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case BudgetPeriod.yearly:
        return (
          start: DateTime(now.year),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  static double computeSpent(
    BudgetEntity budget,
    List<TransactionEntity> transactions, {
    DateTime? reference,
  }) {
    final range = periodRange(budget.period, reference: reference);

    return transactions.where((tx) {
      if (tx.type != TransactionType.expense) return false;
      if (tx.date.isBefore(range.start) || tx.date.isAfter(range.end)) {
        return false;
      }
      if (budget.categoryId != null &&
          budget.categoryId!.isNotEmpty &&
          tx.categoryId != budget.categoryId) {
        return false;
      }
      return true;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  static BudgetProgress toProgress(
    BudgetEntity budget,
    List<TransactionEntity> transactions, {
    DateTime? reference,
  }) {
    final spent = computeSpent(budget, transactions, reference: reference);
    final remaining = budget.amount - spent;
    final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
    final isOverBudget = spent > budget.amount;
    final isAlertTriggered =
        budget.alertEnabled && percentage >= budget.alertThreshold;

    return BudgetProgress(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percentage: percentage.clamp(0.0, double.infinity),
      isOverBudget: isOverBudget,
      isAlertTriggered: isAlertTriggered,
    );
  }
}
