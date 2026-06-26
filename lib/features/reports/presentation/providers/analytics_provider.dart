import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_period.dart';
import 'package:expense_mate/features/reports/domain/utils/analytics_calculator.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unfiltered transaction stream for analytics (ignores list filters).
final allTransactionsStreamProvider =
    StreamProvider.family<List<TransactionEntity>, String>((ref, userId) {
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(userId);
});

final reportPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.monthly);

final analyticsSnapshotProvider =
    Provider.family<AnalyticsSnapshot, String>((ref, userId) {
  final period = ref.watch(reportPeriodProvider);
  final transactions = ref.watch(allTransactionsStreamProvider(userId));
  final categories =
      ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? [];

  return transactions.maybeWhen(
    data: (list) => AnalyticsCalculator.buildSnapshot(
      allTransactions: list,
      categories: categories,
      period: period,
    ),
    orElse: AnalyticsSnapshot.empty,
  );
});

final dashboardAnalyticsProvider =
    Provider.family<AnalyticsSnapshot, String>((ref, userId) {
  final transactions = ref.watch(allTransactionsStreamProvider(userId));
  final categories =
      ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? [];

  return transactions.maybeWhen(
    data: (list) => AnalyticsCalculator.buildSnapshot(
      allTransactions: list,
      categories: categories,
      period: AnalyticsPeriod.monthly,
    ),
    orElse: AnalyticsSnapshot.empty,
  );
});

final weeklySpendingProvider =
    Provider.family<List<ChartDataPoint>, String>((ref, userId) {
  return ref.watch(dashboardAnalyticsProvider(userId)).weeklySpending;
});

final categoryBreakdownProvider =
    Provider.family<List<CategorySpending>, String>((ref, userId) {
  return ref.watch(dashboardAnalyticsProvider(userId)).categoryBreakdown;
});

final monthlyCashFlowProvider =
    Provider.family<List<MonthlyCashFlow>, String>((ref, userId) {
  return ref.watch(dashboardAnalyticsProvider(userId)).monthlyCashFlow;
});

final monthlySummaryProvider =
    Provider.family<IncomeExpenseComparison, String>((ref, userId) {
  return ref.watch(dashboardAnalyticsProvider(userId)).summary;
});
