import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/utils/validators.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Form to create a savings goal.
class AddGoalPage extends ConsumerStatefulWidget {
  const AddGoalPage({super.key});

  @override
  ConsumerState<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends ConsumerState<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _uuid = const Uuid();

  GoalType _type = GoalType.emergencyFund;
  DateTime? _targetDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final goal = GoalEntity(
      id: _uuid.v4(),
      userId: userId,
      name: _nameController.text.trim(),
      type: _type,
      targetAmount: double.parse(_targetController.text),
      targetDate: _targetDate,
      icon: _type.icon,
      color: _type.color,
      syncStatus: SyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final result = await ref.read(goalRepositoryProvider).createGoal(goal);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      context.pop();
      context.showAppSnackBar('Goal created');
    } else {
      context.showAppSnackBar(
        result.failureOrNull?.message ?? 'Failed to create goal',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Goal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Goal Name',
                validator: (v) => Validators.required(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _targetController,
                label: 'Target Amount',
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
              DropdownButtonFormField<GoalType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Goal Type'),
                items: GoalType.values
                    .map(
                      (t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date (optional)'),
                subtitle: Text(
                  _targetDate != null
                      ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                      : 'Not set',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create Goal',
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
