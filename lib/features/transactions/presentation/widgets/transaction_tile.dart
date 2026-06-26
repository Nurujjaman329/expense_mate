import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/extensions/datetime_extensions.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/utils/icon_mapper.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

/// List tile for displaying a transaction with category color.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.wallet,
    this.onTap,
    this.onDelete,
  });

  final TransactionEntity transaction;
  final CategoryEntity? category;
  final WalletEntity? wallet;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  Color get _typeColor => switch (transaction.type) {
        TransactionType.income => AppColors.income,
        TransactionType.expense => AppColors.expense,
        TransactionType.transfer => AppColors.transfer,
      };

  IconData get _typeIcon => switch (transaction.type) {
        TransactionType.income => Icons.arrow_downward_rounded,
        TransactionType.expense => Icons.arrow_upward_rounded,
        TransactionType.transfer => Icons.swap_horiz_rounded,
      };

  String get _amountPrefix => switch (transaction.type) {
        TransactionType.income => '+',
        TransactionType.expense => '-',
        TransactionType.transfer => '',
      };

  @override
  Widget build(BuildContext context) {
    final categoryColor = category != null
        ? Color(category!.color)
        : _typeColor;

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: categoryColor.withValues(alpha: 0.15),
            child: Icon(
              category != null
                  ? IconMapper.fromName(category!.icon)
                  : _typeIcon,
              color: categoryColor,
              size: 22,
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              transaction.date.toDisplayDate(),
              if (wallet != null) wallet!.name,
              if (category != null) category!.name,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_amountPrefix${Formatters.currency(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _typeColor,
                ),
              ),
              if (transaction.syncStatus == SyncStatus.pending)
                const Icon(Icons.cloud_upload_outlined, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
