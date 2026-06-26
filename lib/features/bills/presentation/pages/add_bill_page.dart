import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/utils/validators.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Form to create a bill or recurring reminder.
class AddBillPage extends ConsumerStatefulWidget {
  const AddBillPage({super.key});

  @override
  ConsumerState<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends ConsumerState<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _uuid = const Uuid();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isRecurring = false;
  RecurringRule _recurringRule = RecurringRule.monthly;
  String? _categoryId;
  String? _walletId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final bill = BillEntity(
      id: _uuid.v4(),
      userId: userId,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      categoryId: _categoryId,
      walletId: _walletId,
      dueDate: _dueDate,
      isRecurring: _isRecurring,
      recurringRule: _isRecurring ? _recurringRule : null,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final result = await ref.read(billRepositoryProvider).createBill(bill);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      context.pop();
      context.showAppSnackBar('Bill created');
    } else {
      context.showAppSnackBar(
        result.failureOrNull?.message ?? 'Failed to create bill',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    final categories = userId != null
        ? ref.watch(categoriesStreamProvider(userId)).valueOrNull ?? []
        : <CategoryEntity>[];
    final wallets = userId != null
        ? ref.watch(walletsStreamProvider(userId)).valueOrNull ?? []
        : <WalletEntity>[];
    final expenseCategories =
        categories.where((c) => c.type == TransactionType.expense).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Bill Title',
                validator: (v) => Validators.required(v, fieldName: 'Title'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date'),
                subtitle: Text(Formatters.date(_dueDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickDueDate,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _walletId,
                decoration: const InputDecoration(labelText: 'Wallet (optional)'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...wallets.map(
                    (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration:
                    const InputDecoration(labelText: 'Category (optional)'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...expenseCategories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring bill'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurringRule>(
                  value: _recurringRule,
                  decoration: const InputDecoration(labelText: 'Repeat'),
                  items: RecurringRule.values
                      .map(
                        (r) =>
                            DropdownMenuItem(value: r, child: Text(r.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _recurringRule = v);
                  },
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create Bill',
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
