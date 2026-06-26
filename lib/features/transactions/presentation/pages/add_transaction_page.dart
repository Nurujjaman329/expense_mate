import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/utils/validators.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Create or edit a transaction (income, expense, or transfer).
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({
    super.key,
    this.transactionId,
    this.initialType = TransactionType.expense,
  });

  final String? transactionId;
  final TransactionType initialType;

  @override
  ConsumerState<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _uuid = const Uuid();

  late TransactionType _type;
  String? _walletId;
  String? _transferWalletId;
  String? _categoryId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _isRecurring = false;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (_isEditing) {
      _loadTransaction();
    }
  }

  Future<void> _loadTransaction() async {
    final result = await ref
        .read(transactionRepositoryProvider)
        .getTransactionById(widget.transactionId!);
    final tx = result.dataOrNull;
    if (tx == null || !mounted) return;

    setState(() {
      _type = tx.type;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _walletId = tx.walletId;
      _transferWalletId = tx.transferWalletId;
      _categoryId = tx.categoryId.isEmpty ? null : tx.categoryId;
      _paymentMethod = tx.paymentMethod;
      _date = tx.date;
      _isRecurring = tx.isRecurring;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    if (_walletId == null) {
      context.showAppSnackBar('Please select a wallet', isError: true);
      return;
    }

    if (_type != TransactionType.transfer &&
        (_categoryId == null || _categoryId!.isEmpty)) {
      context.showAppSnackBar('Please select a category', isError: true);
      return;
    }

    if (_type == TransactionType.transfer && _transferWalletId == null) {
      context.showAppSnackBar('Please select destination wallet', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final entity = TransactionEntity(
      id: widget.transactionId ?? _uuid.v4(),
      userId: userId,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.replaceAll(',', '')),
      type: _type,
      walletId: _walletId!,
      categoryId: _categoryId ?? '',
      paymentMethod: _paymentMethod,
      currency: 'USD',
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      transferWalletId: _transferWalletId,
      isRecurring: _isRecurring,
      createdAt: now,
      updatedAt: now,
    );

    final result = _isEditing
        ? await ref
            .read(transactionRepositoryProvider)
            .updateTransaction(entity)
        : await ref
            .read(transactionRepositoryProvider)
            .createTransaction(entity);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      context.pop();
      context.showAppSnackBar(
        _isEditing ? 'Transaction updated' : 'Transaction added',
      );
    } else {
      context.showAppSnackBar(
        result.failureOrNull?.message ?? 'Failed to save',
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

    final wallets = ref.watch(walletsStreamProvider(userId)).valueOrNull ?? [];
    final categoriesAsync = _type == TransactionType.income
        ? ref.watch(incomeCategoriesProvider(userId))
        : ref.watch(expenseCategoriesProvider(userId));
    final categories = categoriesAsync.valueOrNull ?? [];

    if (_walletId == null && wallets.isNotEmpty) {
      var selected = wallets.first;
      for (final wallet in wallets) {
        if (wallet.isDefault) {
          selected = wallet;
          break;
        }
      }
      _walletId = selected.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add ${_type.label}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing)
                SegmentedButton<TransactionType>(
                  segments: TransactionType.values
                      .map(
                        (t) => ButtonSegment(
                          value: t,
                          label: Text(t.label),
                        ),
                      )
                      .toList(),
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() {
                      _type = set.first;
                      _categoryId = null;
                    });
                  },
                ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                validator: (v) => Validators.required(v, fieldName: 'Title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
                prefixIcon: const Icon(Icons.attach_money),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _walletId,
                decoration: InputDecoration(
                  labelText: _type == TransactionType.transfer
                      ? 'From Wallet'
                      : 'Wallet',
                ),
                items: wallets
                    .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _walletId = v),
              ),
              if (_type == TransactionType.transfer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _transferWalletId,
                  decoration: const InputDecoration(labelText: 'To Wallet'),
                  items: wallets
                      .where((w) => w.id != _walletId)
                      .map(
                        (w) =>
                            DropdownMenuItem(value: w.id, child: Text(w.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _transferWalletId = v),
                ),
              ],
              if (_type != TransactionType.transfer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: PaymentMethod.values
                    .map(
                      (m) =>
                          DropdownMenuItem(value: m, child: Text(m.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _paymentMethod = v);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  '${_date.day}/${_date.month}/${_date.year}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _noteController,
                label: 'Note (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring transaction'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Update' : 'Save',
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
