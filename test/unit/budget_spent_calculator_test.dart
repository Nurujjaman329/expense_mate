import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/budget/domain/utils/budget_spent_calculator.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 15, 12);

  BudgetEntity budget({
    String? categoryId,
    BudgetPeriod period = BudgetPeriod.monthly,
    double amount = 1000,
    double alertThreshold = 0.8,
  }) {
    return BudgetEntity(
      id: 'b1',
      userId: 'u1',
      name: 'Food',
      amount: amount,
      period: period,
      categoryId: categoryId,
      alertThreshold: alertThreshold,
      startDate: now,
    );
  }

  TransactionModel expense({
    required String id,
    required double amount,
    String categoryId = 'cat-food',
    DateTime? date,
  }) {
    return TransactionModel(
      id: id,
      userId: 'u1',
      title: 'Expense',
      amount: amount,
      type: TransactionType.expense,
      walletId: 'w1',
      categoryId: categoryId,
      paymentMethod: PaymentMethod.cash,
      currency: 'USD',
      date: date ?? now,
    );
  }

  group('BudgetSpentCalculator', () {
    test('computes spent for monthly budget without category filter', () {
      final txs = [
        expense(id: 't1', amount: 100, date: DateTime(2026, 6, 10)),
        expense(id: 't2', amount: 50, date: DateTime(2026, 6, 20)),
        expense(id: 't3', amount: 200, date: DateTime(2026, 5, 20)),
      ];

      final spent = BudgetSpentCalculator.computeSpent(
        budget(),
        txs,
        reference: now,
      );

      expect(spent, 150);
    });

    test('filters by category when categoryId is set', () {
      final txs = [
        expense(id: 't1', amount: 100, categoryId: 'cat-food'),
        expense(id: 't2', amount: 50, categoryId: 'cat-transport'),
      ];

      final spent = BudgetSpentCalculator.computeSpent(
        budget(categoryId: 'cat-food'),
        txs,
        reference: now,
      );

      expect(spent, 100);
    });

    test('toProgress flags alert when threshold reached', () {
      final txs = [expense(id: 't1', amount: 850)];

      final progress = BudgetSpentCalculator.toProgress(
        budget(amount: 1000, alertThreshold: 0.8),
        txs,
        reference: now,
      );

      expect(progress.isAlertTriggered, isTrue);
      expect(progress.isOverBudget, isFalse);
      expect(progress.percentage, closeTo(0.85, 0.001));
    });

    test('toProgress flags over budget', () {
      final txs = [expense(id: 't1', amount: 1200)];

      final progress = BudgetSpentCalculator.toProgress(
        budget(amount: 1000),
        txs,
        reference: now,
      );

      expect(progress.isOverBudget, isTrue);
      expect(progress.remaining, lessThan(0));
    });
  });
}
