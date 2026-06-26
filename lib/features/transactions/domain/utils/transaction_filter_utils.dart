import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_filter.dart';

/// Pure filter/sort logic for transaction lists.
class TransactionFilterUtils {
  TransactionFilterUtils._();

  static List<T> apply<T extends TransactionEntity>(
    List<T> items,
    TransactionFilter filter,
  ) {
    var result = List<T>.from(items);

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      result = result
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false) ||
                (t.note?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    if (filter.type != null) {
      result = result.where((t) => t.type == filter.type).toList();
    }
    if (filter.categoryId != null) {
      result =
          result.where((t) => t.categoryId == filter.categoryId).toList();
    }
    if (filter.walletId != null) {
      result = result.where((t) => t.walletId == filter.walletId).toList();
    }
    if (filter.paymentMethod != null) {
      result = result
          .where((t) => t.paymentMethod == filter.paymentMethod)
          .toList();
    }
    if (filter.startDate != null) {
      result = result
          .where((t) => !t.date.isBefore(filter.startDate!))
          .toList();
    }
    if (filter.endDate != null) {
      result =
          result.where((t) => !t.date.isAfter(filter.endDate!)).toList();
    }
    if (filter.minAmount != null) {
      result = result.where((t) => t.amount >= filter.minAmount!).toList();
    }
    if (filter.maxAmount != null) {
      result = result.where((t) => t.amount <= filter.maxAmount!).toList();
    }

    result.sort((a, b) {
      int cmp;
      switch (filter.sortBy) {
        case TransactionSortBy.date:
          cmp = a.date.compareTo(b.date);
        case TransactionSortBy.amount:
          cmp = a.amount.compareTo(b.amount);
        case TransactionSortBy.title:
          cmp = a.title.compareTo(b.title);
      }
      return filter.sortOrder == SortOrder.asc ? cmp : -cmp;
    });

    return result;
  }
}
