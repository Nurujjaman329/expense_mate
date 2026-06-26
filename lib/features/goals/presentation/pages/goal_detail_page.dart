import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/utils/icon_mapper.dart';
import 'package:expense_mate/core/utils/validators.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Goal detail with contribution history.
class GoalDetailPage extends ConsumerStatefulWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addContribution(GoalEntity goal) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      context.showAppSnackBar('Enter a valid amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(goalRepositoryProvider).addContribution(
          goal: goal,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      _amountController.clear();
      _noteController.clear();
      context.showAppSnackBar('Contribution added');
    } else {
      context.showAppSnackBar(
        result.failureOrNull?.message ?? 'Failed to add contribution',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final goals = ref.watch(goalsStreamProvider(userId)).valueOrNull ?? [];
    GoalEntity? goal;
    for (final g in goals) {
      if (g.id == widget.goalId) {
        goal = g;
        break;
      }
    }

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal')),
        body: const Center(child: Text('Goal not found')),
      );
    }

    final savingsAsync = ref.watch(savingsByGoalStreamProvider(goal.id));
    final color = goal.color != null
        ? Color(goal.color!)
        : Color(goal.type.color);
    final icon = goal.icon ?? goal.type.icon;

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(IconMapper.fromName(icon),
                          color: color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Formatters.currency(goal.currentAmount),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'of ${Formatters.currency(goal.targetAmount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 10,
                        backgroundColor: color.withValues(alpha: 0.15),
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(0)}% complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Contribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Validators.required(v, fieldName: 'Amount'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: 'Note (optional)',
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Add Contribution',
              isLoading: _isLoading,
              onPressed: () => _addContribution(goal!),
            ),
            const SizedBox(height: 24),
            Text(
              'Contribution History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            savingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (savings) {
                if (savings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No contributions yet')),
                  );
                }
                return Column(
                  children: savings
                      .map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.savings_outlined, size: 20),
                          ),
                          title: Text(Formatters.currency(s.amount)),
                          subtitle: s.note != null ? Text(s.note!) : null,
                          trailing: Text(
                            Formatters.date(s.createdAt ?? DateTime.now()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
