import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/utils/validators.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Form to create a new wallet.
class AddWalletPage extends ConsumerStatefulWidget {
  const AddWalletPage({super.key});

  @override
  ConsumerState<AddWalletPage> createState() => _AddWalletPageState();
}

class _AddWalletPageState extends ConsumerState<AddWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _uuid = const Uuid();

  WalletType _type = WalletType.cash;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final wallet = WalletEntity(
      id: _uuid.v4(),
      userId: userId,
      name: _nameController.text.trim(),
      type: _type,
      balance: double.tryParse(_balanceController.text) ?? 0,
      currency: 'USD',
      icon: _iconForType(_type),
      color: _colorForType(_type),
      isDefault: _isDefault,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final result =
        await ref.read(walletRepositoryProvider).createWallet(wallet);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      context.pop();
      context.showAppSnackBar('Wallet created');
    } else {
      context.showAppSnackBar(
        result.failureOrNull?.message ?? 'Failed to create wallet',
        isError: true,
      );
    }
  }

  String _iconForType(WalletType type) => switch (type) {
        WalletType.cash => 'account_balance_wallet',
        WalletType.bank => 'account_balance',
        WalletType.creditCard || WalletType.debitCard => 'credit_card',
        WalletType.crypto => 'currency_bitcoin',
        _ => 'payments',
      };

  int _colorForType(WalletType type) => switch (type) {
        WalletType.cash => 0xFF00695C,
        WalletType.bank => 0xFF2196F3,
        WalletType.creditCard => 0xFF9C27B0,
        WalletType.bkash || WalletType.nagad || WalletType.rocket => 0xFFE91E63,
        _ => 0xFF607D8B,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Wallet Name',
                validator: (v) => Validators.required(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WalletType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Wallet Type'),
                items: WalletType.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _balanceController,
                label: 'Initial Balance',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default wallet'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create Wallet',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
