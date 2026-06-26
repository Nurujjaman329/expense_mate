import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/reports/domain/entities/analytics_period.dart';
import 'package:expense_mate/features/reports/domain/utils/analytics_calculator.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsCalculator', () {
    final transactions = [
      TransactionModel(
        id: '1',
        userId: 'u1',
        title: 'Salary',
        amount: 5000,
        type: TransactionType.income,
        walletId: 'w1',
        categoryId: 'c1',
        paymentMethod: PaymentMethod.bankTransfer,
        currency: 'USD',
        date: DateTime(2026, 6, 15),
      ),
      TransactionModel(
        id: '2',
        userId: 'u1',
        title: 'Groceries',
        amount: 120,
        type: TransactionType.expense,
        walletId: 'w1',
        categoryId: 'c2',
        paymentMethod: PaymentMethod.cash,
        currency: 'USD',
        date: DateTime(2026, 6, 20),
      ),
      TransactionModel(
        id: '3',
        userId: 'u1',
        title: 'Fuel',
        amount: 50,
        type: TransactionType.expense,
        walletId: 'w1',
        categoryId: 'c3',
        paymentMethod: PaymentMethod.card,
        currency: 'USD',
        date: DateTime(2026, 6, 22),
      ),
    ];

    test('computeComparison calculates income and expense', () {
      final result = AnalyticsCalculator.computeComparison(transactions);
      expect(result.income, 5000);
      expect(result.expense, 170);
      expect(result.net, 4830);
    });

    test('filterByPeriod filters monthly transactions', () {
      final june = AnalyticsCalculator.filterByPeriod(
        transactions,
        AnalyticsPeriod.monthly,
        reference: DateTime(2026, 6, 25),
      );
      expect(june.length, 3);

      final may = AnalyticsCalculator.filterByPeriod(
        transactions,
        AnalyticsPeriod.monthly,
        reference: DateTime(2026, 5, 10),
      );
      expect(may.length, 0);
    });

    test('computeWeeklySpending returns 7 data points', () {
      final weekly = AnalyticsCalculator.computeWeeklySpending(
        transactions,
        reference: DateTime(2026, 6, 25),
      );
      expect(weekly.length, 7);
    });

    test('computeMonthlyCashFlow returns 6 months', () {
      final flow = AnalyticsCalculator.computeMonthlyCashFlow(
        transactions,
        reference: DateTime(2026, 6, 25),
      );
      expect(flow.length, 6);
      expect(flow.last.income, 5000);
      expect(flow.last.expense, 170);
    });
  });
}
