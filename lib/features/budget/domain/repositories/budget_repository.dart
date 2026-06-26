import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';

abstract class BudgetRepository {
  Stream<List<BudgetEntity>> watchBudgets(String userId);

  Future<Result<BudgetEntity>> createBudget(BudgetEntity budget);

  Future<Result<BudgetEntity>> updateBudget(BudgetEntity budget);

  Future<Result<void>> deleteBudget(String id);

  Future<Result<void>> syncFromRemote(String userId);
}
