import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/widgets/charts/cash_flow_chart.dart';
import 'package:expense_mate/core/widgets/charts/category_pie_chart.dart';
import 'package:expense_mate/core/widgets/charts/income_expense_chart.dart';
import 'package:expense_mate/core/widgets/charts/weekly_spending_chart.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_period.dart';
import 'package:expense_mate/features/reports/presentation/providers/analytics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full analytics and reports screen with period selector.
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final period = ref.watch(reportPeriodProvider);
    final analytics = ref.watch(analyticsSnapshotProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
            onPressed: () => context.push(RouteNames.categories),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AnalyticsPeriod.values.map((p) {
                  final selected = period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p.label),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(reportPeriodProvider.notifier).state = p,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _SummaryCards(summary: analytics.summary),
            const SizedBox(height: 24),
            _ChartSection(
              title: 'Income vs Expense',
              child: IncomeExpenseChart(data: analytics.incomeVsExpense),
            ),
            const SizedBox(height: 24),
            _ChartSection(
              title: 'Weekly Spending',
              child: WeeklySpendingChart(data: analytics.weeklySpending),
            ),
            const SizedBox(height: 24),
            _ChartSection(
              title: 'Expense by Category',
              child: CategoryPieChart(data: analytics.categoryBreakdown),
            ),
            const SizedBox(height: 24),
            _ChartSection(
              title: 'Cash Flow (6 Months)',
              child: CashFlowChart(data: analytics.monthlyCashFlow),
            ),
            const SizedBox(height: 24),
            if (analytics.topExpenseCategories.isNotEmpty) ...[
              Text(
                'Top Expenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...analytics.topExpenseCategories.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.color.withValues(alpha: 0.15),
                      child: Icon(Icons.circle, color: item.color, size: 12),
                    ),
                    title: Text(item.categoryName),
                    subtitle: Text(
                      '${(item.percentage * 100).toStringAsFixed(1)}% of expenses',
                    ),
                    trailing: Text(
                      Formatters.currency(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final IncomeExpenseComparison summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Income',
            value: Formatters.currency(summary.income),
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Expense',
            value: Formatters.currency(summary.expense),
            color: AppColors.expense,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Net',
            value: Formatters.currency(summary.net),
            color: summary.net >= 0 ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
