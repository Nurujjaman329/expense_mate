import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/services/user_seed_service.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main dashboard with live balance, summary, and recent transactions.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userDataInitializerProvider);

    final user = ref.watch(authStateProvider).valueOrNull;
    final userId = user?.id;
    final name = user?.displayName?.split(' ').first ?? 'there';

    final totalBalance =
        userId != null ? ref.watch(totalBalanceProvider(userId)) : 0.0;
    final summary =
        userId != null ? ref.watch(monthlySummaryProvider(userId)) : null;
    final recentAsync = userId != null
        ? ref.watch(recentTransactionsProvider(userId))
        : const AsyncValue.data(<dynamic>[]);
    final categories = userId != null
        ? ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? []
        : <CategoryEntity>[];
    final wallets = userId != null
        ? ref.watch(walletsStreamProvider(userId)).valueOrNull ?? []
        : <WalletEntity>[];

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BalanceCard(balance: totalBalance)
                .animate()
                .fadeIn()
                .slideY(begin: 0.1),
            const SizedBox(height: 20),
            _SummaryRow(
              income: summary?.totalIncome ?? 0,
              expense: summary?.totalExpense ?? 0,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
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
            ).animate().fadeIn(delay: 200.ms),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
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
  const _BalanceCard({required this.balance});

  final double balance;

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
          const SizedBox(height: 4),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
        ],
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
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
