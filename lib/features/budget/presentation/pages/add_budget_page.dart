import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/utils/validators.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Form to create a spending budget.
class AddBudgetPage extends ConsumerStatefulWidget {
  const AddBudgetPage({super.key});

  @override
  ConsumerState<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends ConsumerState<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _uuid = const Uuid();

  BudgetPeriod _period = BudgetPeriod.monthly;
  String? _categoryId;
  double _alertThreshold = 0.8;
  bool _alertEnabled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final budget = BudgetEntity(
      id: _uuid.v4(),
      userId: userId,
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      period: _period,
      categoryId: _categoryId,
      alertThreshold: _alertThreshold,
      alertEnabled: _alertEnabled,
      startDate: now,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final result =
        await ref.read(budgetRepositoryProvider).createBudget(budget);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      context.pop();
      context.showAppSnackBar('Budget created');
    } else {
      context.showAppSnackBar(
        result.failureOrNull?.message ?? 'Failed to create budget',
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
    final expenseCategories =
        categories.where((c) => c.type == TransactionType.expense).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Budget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Budget Name',
                validator: (v) => Validators.required(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Limit Amount',
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
              DropdownButtonFormField<BudgetPeriod>(
                value: _period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: BudgetPeriod.values
                    .map(
                      (p) =>
                          DropdownMenuItem(value: p, child: Text(p.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _period = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All expenses'),
                  ),
                  ...expenseCategories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alert when threshold reached'),
                value: _alertEnabled,
                onChanged: (v) => setState(() => _alertEnabled = v),
              ),
              if (_alertEnabled) ...[
                const SizedBox(height: 8),
                Text(
                  'Alert at ${(_alertThreshold * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Slider(
                  value: _alertThreshold,
                  min: 0.5,
                  max: 0.95,
                  divisions: 9,
                  label: '${(_alertThreshold * 100).toInt()}%',
                  onChanged: (v) => setState(() => _alertThreshold = v),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create Budget',
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
