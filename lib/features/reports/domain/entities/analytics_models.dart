import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A single data point for bar/line charts.
class ChartDataPoint extends Equatable {
  const ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
  });

  final String label;
  final double value;
  final DateTime? date;

  @override
  List<Object?> get props => [label, value, date];
}

/// Spending grouped by category for pie charts.
class CategorySpending extends Equatable {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.color,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final Color color;
  final double percentage;

  @override
  List<Object?> get props =>
      [categoryId, categoryName, amount, color, percentage];
}

/// Income vs expense comparison for a period.
class IncomeExpenseComparison extends Equatable {
  const IncomeExpenseComparison({
    required this.income,
    required this.expense,
    required this.net,
    required this.savingsRate,
  });

  final double income;
  final double expense;
  final double net;
  final double savingsRate;

  @override
  List<Object?> get props => [income, expense, net, savingsRate];
}

/// Monthly cash flow data point.
class MonthlyCashFlow extends Equatable {
  const MonthlyCashFlow({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
  });

  final DateTime month;
  final double income;
  final double expense;
  final double net;

  String get label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month.month - 1];
  }

  @override
  List<Object?> get props => [month, income, expense, net];
}

/// Complete analytics snapshot for dashboard/reports.
class AnalyticsSnapshot extends Equatable {
  const AnalyticsSnapshot({
    required this.summary,
    required this.weeklySpending,
    required this.incomeVsExpense,
    required this.categoryBreakdown,
    required this.monthlyCashFlow,
    required this.topExpenseCategories,
  });

  final IncomeExpenseComparison summary;
  final List<ChartDataPoint> weeklySpending;
  final IncomeExpenseComparison incomeVsExpense;
  final List<CategorySpending> categoryBreakdown;
  final List<MonthlyCashFlow> monthlyCashFlow;
  final List<CategorySpending> topExpenseCategories;

  static AnalyticsSnapshot empty() => AnalyticsSnapshot(
        summary: const IncomeExpenseComparison(
          income: 0,
          expense: 0,
          net: 0,
          savingsRate: 0,
        ),
        weeklySpending: const [],
        incomeVsExpense: const IncomeExpenseComparison(
          income: 0,
          expense: 0,
          net: 0,
          savingsRate: 0,
        ),
        categoryBreakdown: const [],
        monthlyCashFlow: const [],
        topExpenseCategories: const [],
      );

  @override
  List<Object?> get props => [
        summary,
        weeklySpending,
        incomeVsExpense,
        categoryBreakdown,
        monthlyCashFlow,
        topExpenseCategories,
      ];
}
