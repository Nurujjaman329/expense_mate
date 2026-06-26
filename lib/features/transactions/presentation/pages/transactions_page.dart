import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/services/user_seed_service.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/widgets/empty_state_widget.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:expense_mate/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full transaction list with search, filter, and sort.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(String userId) {
    final categories = ref.read(categoriesStreamProvider(userId)).valueOrNull ?? [];
    final wallets = ref.read(walletsStreamProvider(userId)).valueOrNull ?? [];
    final filter = ref.read(transactionFilterProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionFilterSheet(
        initialFilter: filter,
        categories: categories,
        wallets: wallets,
        onApply: (f) {
          ref.read(transactionFilterProvider.notifier).state = f.copyWith(
                searchQuery: _searchController.text,
              );
        },
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final result =
        await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    if (!mounted) return;
    if (result is Error) {
      context.showAppSnackBar(result.failureOrNull!.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userDataInitializerProvider);
    final userId = ref.watch(authStateProvider).valueOrNull?.id;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final transactionsAsync = ref.watch(transactionsStreamProvider(userId));
    final categories =
        ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? [];
    final wallets = ref.watch(walletsStreamProvider(userId)).valueOrNull ?? [];
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filter.hasActiveFilters,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () => _openFilterSheet(userId),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(transactionFilterProvider.notifier).state =
                              filter.copyWith(searchQuery: '');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(searchQuery: value);
              },
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No transactions',
                    message: 'Add your first income or expense to get started.',
                    icon: Icons.receipt_long_outlined,
                    actionLabel: 'Add Transaction',
                    onAction: () => context.push(
                      '${RouteNames.addTransaction}?type=expense',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final category = _findCategory(categories, tx.categoryId);
                    final wallet = _findWallet(wallets, tx.walletId);

                    return TransactionTile(
                      transaction: tx,
                      category: category,
                      wallet: wallet,
                      onTap: () => context.push(
                        '${RouteNames.addTransaction}?id=${tx.id}',
                      ),
                      onDelete: () => _deleteTransaction(tx.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: AppColors.income),
              title: const Text('Income'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('${RouteNames.addTransaction}?type=income');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: AppColors.expense),
              title: const Text('Expense'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('${RouteNames.addTransaction}?type=expense');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.swap_horiz, color: AppColors.transfer),
              title: const Text('Transfer'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('${RouteNames.addTransaction}?type=transfer');
              },
            ),
          ],
        ),
      ),
    );
  }
}

CategoryEntity? _findCategory(List<CategoryEntity> list, String id) {
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
}

WalletEntity? _findWallet(List<WalletEntity> list, String id) {
  for (final w in list) {
    if (w.id == id) return w;
  }
  return null;
}
