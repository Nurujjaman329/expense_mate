import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/widgets/empty_state_widget.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';
import 'package:expense_mate/features/bills/domain/utils/bill_due_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lists bills with due dates and pay actions.
class BillsPage extends ConsumerWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final billsAsync = ref.watch(billsStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.addBill),
          ),
        ],
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyStateWidget(
              title: 'No bills yet',
              message: 'Track recurring bills and due dates.',
              actionLabel: 'Add Bill',
              onAction: () => context.push(RouteNames.addBill),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) => _BillCard(
              bill: bills[index],
              onMarkPaid: () async {
                final result = await ref
                    .read(billRepositoryProvider)
                    .markAsPaid(bills[index]);
                if (context.mounted) {
                  if (result is Success) {
                    context.showAppSnackBar('Bill marked as paid');
                  } else {
                    context.showAppSnackBar(
                      result.failureOrNull!.message,
                      isError: true,
                    );
                  }
                }
              },
              onDelete: () async {
                final result = await ref
                    .read(billRepositoryProvider)
                    .deleteBill(bills[index].id);
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
        onPressed: () => context.push(RouteNames.addBill),
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.onMarkPaid,
    required this.onDelete,
  });

  final BillEntity bill;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final overdue = BillDueUtils.isOverdue(bill);
    final dueSoon = BillDueUtils.isDueSoon(bill);
    final days = BillDueUtils.daysUntilDue(bill);

    Color statusColor = AppColors.textSecondaryLight;
    String statusLabel = Formatters.date(bill.dueDate);
    if (bill.isPaid) {
      statusColor = AppColors.income;
      statusLabel = 'Paid';
    } else if (overdue) {
      statusColor = AppColors.error;
      statusLabel = 'Overdue by ${days.abs()} day(s)';
    } else if (dueSoon) {
      statusColor = AppColors.warning;
      statusLabel = days == 0 ? 'Due today' : 'Due in $days day(s)';
    }

    return Dismissible(
      key: Key(bill.id),
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
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Icon(
              bill.isRecurring ? Icons.repeat : Icons.receipt_long_outlined,
              color: statusColor,
            ),
          ),
          title: Text(
            bill.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: bill.isPaid && !bill.isRecurring
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Text(
            statusLabel,
            style: TextStyle(color: statusColor),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.currency(bill.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!bill.isPaid || bill.isRecurring) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Mark as paid',
                  onPressed: onMarkPaid,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
