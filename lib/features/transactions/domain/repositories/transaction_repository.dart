import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_filter.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> watchTransactions(
    String userId, {
    TransactionFilter? filter,
  });

  Future<Result<List<TransactionEntity>>> getRecentTransactions(
    String userId, {
    int limit = 5,
  });

  Future<Result<TransactionEntity>> getTransactionById(String id);

  Future<Result<TransactionEntity>> createTransaction(
    TransactionEntity transaction,
  );

  Future<Result<TransactionEntity>> updateTransaction(
    TransactionEntity transaction,
  );

  Future<Result<void>> deleteTransaction(String id);

  Future<Result<void>> syncFromRemote(String userId);
}

/// Monthly income/expense totals for dashboard.
class TransactionSummary {
  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;
}
