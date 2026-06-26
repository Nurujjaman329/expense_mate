import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';

abstract class GoalRepository {
  Stream<List<GoalEntity>> watchGoals(String userId);

  Stream<List<SavingEntity>> watchSavingsByGoal(String goalId);

  Future<Result<GoalEntity>> createGoal(GoalEntity goal);

  Future<Result<GoalEntity>> updateGoal(GoalEntity goal);

  Future<Result<void>> deleteGoal(String id);

  Future<Result<GoalEntity>> addContribution({
    required GoalEntity goal,
    required double amount,
    String? note,
  });

  Future<Result<void>> syncFromRemote(String userId);
}
