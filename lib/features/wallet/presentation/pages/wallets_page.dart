import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/utils/icon_mapper.dart';
import 'package:expense_mate/core/widgets/empty_state_widget.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lists all user wallets with balances.
class WalletsPage extends ConsumerWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final walletsAsync = ref.watch(walletsStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.addWallet),
          ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (wallets) {
          if (wallets.isEmpty) {
            return EmptyStateWidget(
              title: 'No wallets',
              message: 'Create a wallet to track your money.',
              actionLabel: 'Add Wallet',
              onAction: () => context.push(RouteNames.addWallet),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            itemBuilder: (context, index) =>
                _WalletCard(wallet: wallets[index], onDelete: () async {
              final result = await ref
                  .read(walletRepositoryProvider)
                  .deleteWallet(wallets[index].id);
              if (context.mounted && result is Error) {
                context.showAppSnackBar(
                  result.failureOrNull!.message,
                  isError: true,
                );
              }
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addWallet),
        icon: const Icon(Icons.add),
        label: const Text('Add Wallet'),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.onDelete});

  final WalletEntity wallet;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = wallet.color != null
        ? Color(wallet.color!)
        : AppColors.primary;

    return Dismissible(
      key: Key(wallet.id),
      direction: wallet.isDefault
          ? DismissDirection.none
          : DismissDirection.endToStart,
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
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              IconMapper.fromName(wallet.icon),
              color: color,
            ),
          ),
          title: Row(
            children: [
              Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (wallet.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(wallet.type.label),
          trailing: Text(
            Formatters.currency(wallet.balance, symbol: '\$'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
