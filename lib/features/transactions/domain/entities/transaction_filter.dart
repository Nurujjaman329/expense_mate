import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

enum TransactionSortBy { date, amount, title }

enum SortOrder { asc, desc }

/// Filter and sort options for transaction lists.
class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.searchQuery = '',
    this.type,
    this.categoryId,
    this.walletId,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortBy = TransactionSortBy.date,
    this.sortOrder = SortOrder.desc,
  });

  final String searchQuery;
  final TransactionType? type;
  final String? categoryId;
  final String? walletId;
  final PaymentMethod? paymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final TransactionSortBy sortBy;
  final SortOrder sortOrder;

  TransactionFilter copyWith({
    String? searchQuery,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    PaymentMethod? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    TransactionSortBy? sortBy,
    SortOrder? sortOrder,
    bool clearType = false,
    bool clearCategory = false,
    bool clearWallet = false,
  }) {
    return TransactionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      type != null ||
      categoryId != null ||
      walletId != null ||
      paymentMethod != null ||
      startDate != null ||
      endDate != null ||
      minAmount != null ||
      maxAmount != null;

  @override
  List<Object?> get props => [
        searchQuery,
        type,
        categoryId,
        walletId,
        paymentMethod,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        sortBy,
        sortOrder,
      ];
}
