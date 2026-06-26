import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_filter.dart';
import 'package:expense_mate/features/transactions/domain/utils/transaction_filter_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFilterUtils', () {
    final sample = [
      TransactionModel(
        id: '1',
        userId: 'u1',
        title: 'Groceries',
        amount: 50,
        type: TransactionType.expense,
        walletId: 'w1',
        categoryId: 'c1',
        paymentMethod: PaymentMethod.cash,
        currency: 'USD',
        date: DateTime(2026, 6, 1),
      ),
      TransactionModel(
        id: '2',
        userId: 'u1',
        title: 'Salary',
        amount: 3000,
        type: TransactionType.income,
        walletId: 'w1',
        categoryId: 'c2',
        paymentMethod: PaymentMethod.bankTransfer,
        currency: 'USD',
        date: DateTime(2026, 6, 15),
      ),
    ];

    test('filters by type', () {
      final result = TransactionFilterUtils.apply(
        sample,
        const TransactionFilter(type: TransactionType.income),
      );
      expect(result.length, 1);
      expect(result.first.title, 'Salary');
    });

    test('filters by search query', () {
      final result = TransactionFilterUtils.apply(
        sample,
        const TransactionFilter(searchQuery: 'groc'),
      );
      expect(result.length, 1);
      expect(result.first.title, 'Groceries');
    });

    test('sorts by amount descending', () {
      final result = TransactionFilterUtils.apply(
        sample,
        const TransactionFilter(sortBy: TransactionSortBy.amount),
      );
      expect(result.first.amount, 3000);
    });
  });
}
