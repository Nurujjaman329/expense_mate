import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_period.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';

/// Pure functions to compute chart data from transactions.
class AnalyticsCalculator {
  AnalyticsCalculator._();

  static List<TransactionEntity> filterByPeriod(
    List<TransactionEntity> transactions,
    AnalyticsPeriod period, {
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    return transactions.where((tx) {
      switch (period) {
        case AnalyticsPeriod.daily:
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        case AnalyticsPeriod.weekly:
          final start = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeek = DateTime(start.year, start.month, start.day);
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return !tx.date.isBefore(startOfWeek) && !tx.date.isAfter(endOfWeek);
        case AnalyticsPeriod.monthly:
          return tx.date.year == now.year && tx.date.month == now.month;
        case AnalyticsPeriod.yearly:
          return tx.date.year == now.year;
      }
    }).toList();
  }

  static IncomeExpenseComparison computeComparison(
    List<TransactionEntity> transactions,
  ) {
    var income = 0.0;
    var expense = 0.0;

    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
        case TransactionType.expense:
          expense += tx.amount;
        case TransactionType.transfer:
          break;
      }
    }

    final net = income - expense;
    final savingsRate = income > 0 ? net / income : 0.0;

    return IncomeExpenseComparison(
      income: income,
      expense: expense,
      net: net,
      savingsRate: savingsRate,
    );
  }

  /// Last 7 days expense totals (Mon–Sun labels for current week slice).
  static List<ChartDataPoint> computeWeeklySpending(
    List<TransactionEntity> transactions, {
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final dayStart = DateTime(day.year, day.month, day.day);
      final total = transactions
          .where(
            (tx) =>
                tx.type == TransactionType.expense &&
                tx.date.year == dayStart.year &&
                tx.date.month == dayStart.month &&
                tx.date.day == dayStart.day,
          )
          .fold(0.0, (sum, tx) => sum + tx.amount);

      return ChartDataPoint(
        label: dayLabels[day.weekday - 1],
        value: total,
        date: dayStart,
      );
    });
  }

  static List<CategorySpending> computeCategoryBreakdown(
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories, {
    TransactionType type = TransactionType.expense,
    int maxItems = 8,
  }) {
    final filtered =
        transactions.where((tx) => tx.type == type).toList();
    if (filtered.isEmpty) return [];

    final totals = <String, double>{};
    for (final tx in filtered) {
      if (tx.categoryId.isEmpty) continue;
      totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
    }

    if (totals.isEmpty) return [];

    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);
    final items = totals.entries.map((entry) {
      CategoryEntity? category;
      for (final c in categories) {
        if (c.id == entry.key) {
          category = c;
          break;
        }
      }
      final color = category != null
          ? Color(category.color)
          : AppColors.chartPalette[
              entry.key.hashCode.abs() % AppColors.chartPalette.length];

      return CategorySpending(
        categoryId: entry.key,
        categoryName: category?.name ?? 'Other',
        amount: entry.value,
        color: color,
        percentage: grandTotal > 0 ? entry.value / grandTotal : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return items.take(maxItems).toList();
  }

  static List<MonthlyCashFlow> computeMonthlyCashFlow(
    List<TransactionEntity> transactions, {
    int months = 6,
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    return List.generate(months, (index) {
      final monthDate = DateTime(now.year, now.month - (months - 1 - index));
      final monthTx = transactions.where(
        (tx) =>
            tx.date.year == monthDate.year && tx.date.month == monthDate.month,
      );
      final comparison = computeComparison(monthTx.toList());
      return MonthlyCashFlow(
        month: monthDate,
        income: comparison.income,
        expense: comparison.expense,
        net: comparison.net,
      );
    });
  }

  static AnalyticsSnapshot buildSnapshot({
    required List<TransactionEntity> allTransactions,
    required List<CategoryEntity> categories,
    AnalyticsPeriod period = AnalyticsPeriod.monthly,
    DateTime? reference,
  }) {
    final periodTx = filterByPeriod(allTransactions, period, reference: reference);
    final comparison = computeComparison(periodTx);
    final breakdown = computeCategoryBreakdown(periodTx, categories);
    final weekly = computeWeeklySpending(allTransactions, reference: reference);
    final cashFlow = computeMonthlyCashFlow(allTransactions, reference: reference);

    return AnalyticsSnapshot(
      summary: comparison,
      weeklySpending: weekly,
      incomeVsExpense: comparison,
      categoryBreakdown: breakdown,
      monthlyCashFlow: cashFlow,
      topExpenseCategories: breakdown.take(5).toList(),
    );
  }
}
