import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/widgets/empty_state_widget.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lists budgets with spending progress.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final progressList = ref.watch(budgetProgressListProvider(userId));
    final categories =
        ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.addBudget),
          ),
        ],
      ),
      body: progressList.isEmpty
          ? EmptyStateWidget(
              title: 'No budgets yet',
              message: 'Set spending limits to stay on track.',
              actionLabel: 'Add Budget',
              onAction: () => context.push(RouteNames.addBudget),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: progressList.length,
              itemBuilder: (context, index) {
                final progress = progressList[index];
                CategoryEntity? category;
                for (final c in categories) {
                  if (c.id == progress.budget.categoryId) {
                    category = c;
                    break;
                  }
                }
                return _BudgetCard(
                  progress: progress,
                  categoryName: category?.name,
                  onDelete: () async {
                    final result = await ref
                        .read(budgetRepositoryProvider)
                        .deleteBudget(progress.budget.id);
                    if (context.mounted && result is Error) {
                      context.showAppSnackBar(
                        result.failureOrNull!.message,
                        isError: true,
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addBudget),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.onDelete,
    this.categoryName,
  });

  final BudgetProgress progress;
  final String? categoryName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final budget = progress.budget;
    final pct = progress.percentage.clamp(0.0, 1.0);
    final barColor = progress.isOverBudget
        ? AppColors.error
        : progress.isAlertTriggered
            ? AppColors.warning
            : AppColors.primary;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budget.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (progress.isOverBudget)
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${budget.period.label}${categoryName != null ? ' · $categoryName' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: barColor.withValues(alpha: 0.15),
                  color: barColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${Formatters.currency(progress.spent)} spent',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${Formatters.currency(budget.amount)} limit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
