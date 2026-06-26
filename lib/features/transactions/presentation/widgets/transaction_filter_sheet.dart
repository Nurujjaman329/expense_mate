import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_filter.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for filtering and sorting transactions.
class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.categories,
    required this.wallets,
    required this.onApply,
  });

  final TransactionFilter initialFilter;
  final List<CategoryEntity> categories;
  final List<WalletEntity> wallets;
  final ValueChanged<TransactionFilter> onApply;

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & Sort',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filter.type == null,
                onSelected: (_) =>
                    setState(() => _filter = _filter.copyWith(clearType: true)),
              ),
              ...TransactionType.values.map(
                (type) => FilterChip(
                  label: Text(type.label),
                  selected: _filter.type == type,
                  onSelected: (selected) => setState(
                    () => _filter = _filter.copyWith(
                      type: selected ? type : null,
                      clearType: !selected,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Wallet', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _filter.walletId,
            decoration: const InputDecoration(labelText: 'Select wallet'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All wallets')),
              ...widget.wallets.map(
                (w) => DropdownMenuItem(value: w.id, child: Text(w.name)),
              ),
            ],
            onChanged: (value) => setState(
              () => _filter = _filter.copyWith(
                walletId: value,
                clearWallet: value == null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _filter.categoryId,
            decoration: const InputDecoration(labelText: 'Select category'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All categories')),
              ...widget.categories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (value) => setState(
              () => _filter = _filter.copyWith(
                categoryId: value,
                clearCategory: value == null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sort by', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<TransactionSortBy>(
            segments: const [
              ButtonSegment(
                value: TransactionSortBy.date,
                label: Text('Date'),
              ),
              ButtonSegment(
                value: TransactionSortBy.amount,
                label: Text('Amount'),
              ),
              ButtonSegment(
                value: TransactionSortBy.title,
                label: Text('Title'),
              ),
            ],
            selected: {_filter.sortBy},
            onSelectionChanged: (set) =>
                setState(() => _filter = _filter.copyWith(sortBy: set.first)),
          ),
          const SizedBox(height: 12),
          SegmentedButton<SortOrder>(
            segments: const [
              ButtonSegment(value: SortOrder.desc, label: Text('Desc')),
              ButtonSegment(value: SortOrder.asc, label: Text('Asc')),
            ],
            selected: {_filter.sortOrder},
            onSelectionChanged: (set) => setState(
              () => _filter = _filter.copyWith(sortOrder: set.first),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(const TransactionFilter());
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filter);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
