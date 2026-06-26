import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';
import 'package:expense_mate/features/bills/domain/utils/bill_due_utils.dart';
import 'package:expense_mate/core/services/notification_service.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/widgets/charts/cash_flow_chart.dart';
import 'package:expense_mate/core/widgets/charts/category_pie_chart.dart';
import 'package:expense_mate/core/widgets/charts/income_expense_chart.dart';
import 'package:expense_mate/core/widgets/charts/weekly_spending_chart.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';
import 'package:expense_mate/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:expense_mate/core/services/user_seed_service.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_models.dart';
import 'package:expense_mate/features/reports/presentation/providers/analytics_provider.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main dashboard with balance, analytics charts, and recent transactions.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userDataInitializerProvider);
    ref.watch(notificationRefreshProvider);

    final user = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.id;
    final name = user?.displayName?.split(' ').first ?? 'there';

    final totalBalance =
        userId != null ? ref.watch(totalBalanceProvider(userId)) : 0.0;
    final analytics = userId != null
        ? ref.watch(dashboardAnalyticsProvider(userId))
        : null;
    final recentAsync = userId != null
        ? ref.watch(recentTransactionsProvider(userId))
        : const AsyncValue.data(<dynamic>[]);
    final categories = userId != null
        ? ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? []
        : <CategoryEntity>[];
    final wallets = userId != null
        ? ref.watch(walletsStreamProvider(userId)).valueOrNull ?? []
        : <WalletEntity>[];
    final budgetAlerts = userId != null
        ? ref.watch(budgetAlertsProvider(userId))
        : <BudgetProgress>[];
    final activeGoals = userId != null
        ? ref.watch(activeGoalsProvider(userId))
        : <GoalEntity>[];
    final upcomingBills = userId != null
        ? ref.watch(upcomingBillsProvider(userId))
        : <BillEntity>[];
    final unreadCount = userId != null
        ? ref.watch(unreadNotificationCountProvider(userId))
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.push(RouteNames.notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Full Reports',
            onPressed: () => context.go(RouteNames.reports),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userId != null) {
            ref.invalidate(allTransactionsStreamProvider(userId));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BalanceCard(
                balance: totalBalance,
                savingsRate: analytics?.summary.savingsRate ?? 0,
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 20),
              _SummaryRow(
                income: analytics?.summary.income ?? 0,
                expense: analytics?.summary.expense ?? 0,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              if (budgetAlerts.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BudgetAlertsSection(alerts: budgetAlerts)
                    .animate()
                    .fadeIn(delay: 120.ms),
              ],
              if (activeGoals.isNotEmpty) ...[
                const SizedBox(height: 16),
                _GoalsSection(
                  goals: activeGoals.take(3).toList(),
                  onSeeAll: () => context.push(RouteNames.goals),
                ).animate().fadeIn(delay: 130.ms),
              ],
              if (upcomingBills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _UpcomingBillsSection(
                  bills: upcomingBills.take(3).toList(),
                  onSeeAll: () => context.push(RouteNames.bills),
                ).animate().fadeIn(delay: 140.ms),
              ],
              const SizedBox(height: 24),
              _ChartCard(
                title: 'Weekly Spending',
                onSeeAll: () => context.go(RouteNames.reports),
                child: WeeklySpendingChart(
                  data: analytics?.weeklySpending ?? [],
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Income vs Expense',
                child: IncomeExpenseChart(
                  data: analytics?.incomeVsExpense ??
                      const IncomeExpenseComparison(
                        income: 0,
                        expense: 0,
                        net: 0,
                        savingsRate: 0,
                      ),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              if ((analytics?.categoryBreakdown ?? []).isNotEmpty)
                _ChartCard(
                  title: 'Top Categories',
                  child: CategoryPieChart(
                    data: analytics!.categoryBreakdown,
                    size: 160,
                  ),
                ).animate().fadeIn(delay: 250.ms),
              if ((analytics?.categoryBreakdown ?? []).isNotEmpty)
                const SizedBox(height: 16),
              _ChartCard(
                title: 'Cash Flow Trend',
                child: CashFlowChart(
                  data: analytics?.monthlyCashFlow ?? [],
                  height: 180,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _QuickActions(
                onIncome: () => context.push(
                  '${RouteNames.addTransaction}?type=income',
                ),
                onExpense: () => context.push(
                  '${RouteNames.addTransaction}?type=expense',
                ),
                onTransfer: () => context.push(
                  '${RouteNames.addTransaction}?type=transfer',
                ),
                onBudgets: () => context.push(RouteNames.budgets),
                onGoals: () => context.push(RouteNames.goals),
                onBills: () => context.push(RouteNames.bills),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.transactions),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const _EmptyTransactionsPlaceholder();
                  }
                  return Column(
                    children: transactions.map((tx) {
                      CategoryEntity? category;
                      for (final c in categories) {
                        if (c.id == tx.categoryId) {
                          category = c;
                          break;
                        }
                      }
                      WalletEntity? wallet;
                      for (final w in wallets) {
                        if (w.id == tx.walletId) {
                          wallet = w;
                          break;
                        }
                      }
                      return TransactionTile(
                        transaction: tx,
                        category: category,
                        wallet: wallet,
                        onTap: () => context.push(
                          '${RouteNames.addTransaction}?id=${tx.id}',
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '${RouteNames.addTransaction}?type=expense',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.savingsRate});

  final double balance;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(balance),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
              const Spacer(),
              if (savingsRate != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(savingsRate * 100).toStringAsFixed(0)}% saved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.onSeeAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (onSeeAll != null)
                  TextButton(onPressed: onSeeAll, child: const Text('Details')),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Income',
            amount: Formatters.currency(income),
            color: AppColors.income,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Expense',
            amount: Formatters.currency(expense),
            color: AppColors.expense,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Net',
            amount: Formatters.currency(income - expense),
            color: AppColors.savings,
            icon: Icons.savings_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onIncome,
    required this.onExpense,
    required this.onTransfer,
    required this.onBudgets,
    required this.onGoals,
    required this.onBills,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onTransfer;
  final VoidCallback onBudgets;
  final VoidCallback onGoals;
  final VoidCallback onBills;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceAround,
      children: [
        _ActionButton(
          label: 'Income',
          icon: Icons.add_circle_outline,
          color: AppColors.income,
          onTap: onIncome,
        ),
        _ActionButton(
          label: 'Expense',
          icon: Icons.remove_circle_outline,
          color: AppColors.expense,
          onTap: onExpense,
        ),
        _ActionButton(
          label: 'Transfer',
          icon: Icons.swap_horiz_rounded,
          color: AppColors.transfer,
          onTap: onTransfer,
        ),
        _ActionButton(
          label: 'Budgets',
          icon: Icons.pie_chart_outline,
          color: AppColors.warning,
          onTap: onBudgets,
        ),
        _ActionButton(
          label: 'Goals',
          icon: Icons.flag_outlined,
          color: AppColors.savings,
          onTap: onGoals,
        ),
        _ActionButton(
          label: 'Bills',
          icon: Icons.receipt_long_outlined,
          color: AppColors.info,
          onTap: onBills,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyTransactionsPlaceholder extends StatelessWidget {
  const _EmptyTransactionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first transaction',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAlertsSection extends StatelessWidget {
  const _BudgetAlertsSection({required this.alerts});

  final List<BudgetProgress> alerts;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Budget Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.take(3).map((alert) {
              final label = alert.isOverBudget
                  ? '${alert.budget.name} is over budget'
                  : '${alert.budget.name} at ${(alert.percentage * 100).toInt()}%';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    Text(
                      Formatters.currency(alert.spent),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals, required this.onSeeAll});

  final List<GoalEntity> goals;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings Goals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 12),
            ...goals.map((goal) {
              final color = goal.color != null
                  ? Color(goal.color!)
                  : Color(goal.type.color);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(goal.name),
                        Text(
                          '${(goal.progress * 100).toInt()}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBillsSection extends StatelessWidget {
  const _UpcomingBillsSection({
    required this.bills,
    required this.onSeeAll,
  });

  final List<BillEntity> bills;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Bills',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 12),
            ...bills.map((bill) {
              final overdue = BillDueUtils.isOverdue(bill);
              final days = BillDueUtils.daysUntilDue(bill);
              final label = overdue
                  ? 'Overdue ${days.abs()}d'
                  : days == 0
                      ? 'Due today'
                      : 'Due in ${days}d';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bill.title),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: overdue
                                  ? AppColors.error
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.currency(bill.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
