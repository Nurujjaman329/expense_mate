import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/utils/csv_export_builder.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tx = TransactionModel(
    id: '1',
    userId: 'u1',
    title: 'Coffee, "special"',
    amount: 4.5,
    type: TransactionType.expense,
    walletId: 'w1',
    categoryId: 'c1',
    paymentMethod: PaymentMethod.cash,
    currency: 'USD',
    date: DateTime(2026, 6, 15),
    note: 'Morning\nbreak',
  );

  group('CsvExportBuilder', () {
    test('builds header and row', () {
      final csv = CsvExportBuilder.build(
        transactions: [tx],
        categoryNames: {'c1': 'Food'},
        walletNames: {'w1': 'Cash'},
      );

      expect(csv.startsWith('Date,Title,Type'), isTrue);
      expect(csv.contains('"Coffee, ""special"""'), isTrue);
      expect(csv.contains('Food'), isTrue);
    });

    test('escapes commas in values', () {
      final csv = CsvExportBuilder.build(
        transactions: [
          TransactionModel(
            id: '2',
            userId: 'u1',
            title: 'Shop A, Shop B',
            amount: 10,
            type: TransactionType.expense,
            walletId: 'w1',
            categoryId: 'c1',
            paymentMethod: PaymentMethod.card,
            currency: 'USD',
            date: DateTime(2026, 6, 1),
          ),
        ],
        categoryNames: const {},
        walletNames: const {},
      );

      expect(csv.contains('"Shop A, Shop B"'), isTrue);
    });
  });
}
