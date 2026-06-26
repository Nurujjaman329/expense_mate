import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/utils/icon_mapper.dart';
import 'package:expense_mate/core/widgets/empty_state_widget.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lists savings goals with progress.
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final goalsAsync = ref.watch(goalsStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.addGoal),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyStateWidget(
              title: 'No goals yet',
              message: 'Create a savings goal and track your progress.',
              actionLabel: 'Add Goal',
              onAction: () => context.push(RouteNames.addGoal),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) => _GoalCard(
              goal: goals[index],
              onTap: () => context.push(
                '${RouteNames.goalDetail}?id=${goals[index].id}',
              ),
              onDelete: () async {
                final result = await ref
                    .read(goalRepositoryProvider)
                    .deleteGoal(goals[index].id);
                if (context.mounted && result is Error) {
                  context.showAppSnackBar(
                    result.failureOrNull!.message,
                    isError: true,
                  );
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addGoal),
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onDelete,
  });

  final GoalEntity goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = goal.color != null
        ? Color(goal.color!)
        : Color(goal.type.color);
    final icon = goal.icon ?? goal.type.icon;

    return Dismissible(
      key: Key(goal.id),
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(IconMapper.fromName(icon), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            goal.type.label,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (goal.isCompleted)
                      const Icon(Icons.check_circle, color: AppColors.income),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.currency(goal.currentAmount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      Formatters.currency(goal.targetAmount),
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
      ),
    );
  }
}
