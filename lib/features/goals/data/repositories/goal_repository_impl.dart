import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/goals/data/datasource/goal_datasource.dart';
import 'package:expense_mate/features/goals/data/models/goal_model.dart';
import 'package:expense_mate/features/goals/domain/entities/goal_entity.dart';
import 'package:expense_mate/features/goals/domain/repositories/goal_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl({
    required GoalLocalDataSource local,
    required GoalRemoteDataSource remote,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final GoalLocalDataSource _local;
  final GoalRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;
  final _uuid = const Uuid();

  Future<void> _saveGoal(GoalModel model, String operation) async {
    await _local.upsertGoal(model);
    await _local.enqueueGoalSync(model, operation);
    if (await _networkInfo.isConnected) await _syncEngine.syncAll();
  }

  @override
  Stream<List<GoalEntity>> watchGoals(String userId) {
    return _local.watchGoals(userId).map((list) => list);
  }

  @override
  Stream<List<SavingEntity>> watchSavingsByGoal(String goalId) {
    return _local.watchSavingsByGoal(goalId).map((list) => list);
  }

  @override
  Future<Result<GoalEntity>> createGoal(GoalEntity goal) async {
    try {
      final now = DateTime.now();
      final model = GoalModel.fromEntity(goal).copyWithPending(now);
      await _saveGoal(model, 'create');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GoalEntity>> updateGoal(GoalEntity goal) async {
    try {
      final model =
          GoalModel.fromEntity(goal).copyWithUpdated(DateTime.now());
      await _saveGoal(model, 'update');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    try {
      final now = DateTime.now();
      await _local.softDeleteGoal(id, now);
      await _local.enqueueGoalSync(
        GoalModel(
          id: id,
          userId: '',
          name: '',
          type: GoalType.other,
          targetAmount: 0,
          syncStatus: SyncStatus.pending,
          updatedAt: now,
        ),
        'delete',
      );
      if (await _networkInfo.isConnected) await _syncEngine.syncAll();
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<GoalEntity>> addContribution({
    required GoalEntity goal,
    required double amount,
    String? note,
  }) async {
    try {
      final now = DateTime.now();
      final saving = SavingModel(
        id: _uuid.v4(),
        userId: goal.userId,
        goalId: goal.id,
        name: 'Contribution to ${goal.name}',
        amount: amount,
        note: note,
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await _local.upsertSaving(saving);
      await _local.enqueueSavingSync(saving, 'create');

      final updatedGoal = GoalModel.fromEntity(goal).copyWithUpdated(
        now,
        currentAmount: goal.currentAmount + amount,
      );
      await _saveGoal(updatedGoal, 'update');
      return Success(updatedGoal);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncFromRemote(String userId) async {
    try {
      if (!await _networkInfo.isConnected) return const Success(null);

      final remoteGoals = await _remote.fetchGoals(userId);
      for (final goal in remoteGoals) {
        await _local.upsertGoal(
          GoalModel(
            id: goal.id,
            userId: goal.userId,
            name: goal.name,
            type: goal.type,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            targetDate: goal.targetDate,
            icon: goal.icon,
            color: goal.color,
            syncStatus: SyncStatus.synced,
            createdAt: goal.createdAt,
            updatedAt: goal.updatedAt,
          ),
        );
      }

      final remoteSavings = await _remote.fetchSavings(userId);
      for (final saving in remoteSavings) {
        await _local.upsertSaving(
          SavingModel(
            id: saving.id,
            userId: saving.userId,
            goalId: saving.goalId,
            name: saving.name,
            amount: saving.amount,
            currency: saving.currency,
            note: saving.note,
            syncStatus: SyncStatus.synced,
            createdAt: saving.createdAt,
            updatedAt: saving.updatedAt,
          ),
        );
      }

      await _syncEngine.syncAll();
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}

extension on GoalModel {
  GoalModel copyWithPending(DateTime now) {
    return GoalModel(
      id: id,
      userId: userId,
      name: name,
      type: type,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      icon: icon ?? type.icon,
      color: color ?? type.color,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  GoalModel copyWithUpdated(
    DateTime updatedAt, {
    double? currentAmount,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      name: name,
      type: type,
      targetAmount: targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate,
      icon: icon,
      color: color,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final goalLocalDataSourceProvider = Provider<GoalLocalDataSource>((ref) {
  return GoalLocalDataSource(ref.watch(appDatabaseProvider));
});

final goalRemoteDataSourceProvider = Provider<GoalRemoteDataSource>((ref) {
  return GoalRemoteDataSource(ref.watch(firestoreProvider));
});

final goalRepositoryImplProvider = Provider<GoalRepositoryImpl>((ref) {
  return GoalRepositoryImpl(
    local: ref.watch(goalLocalDataSourceProvider),
    remote: ref.watch(goalRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return ref.watch(goalRepositoryImplProvider);
});

final goalsStreamProvider =
    StreamProvider.family<List<GoalEntity>, String>((ref, userId) {
  return ref.watch(goalRepositoryProvider).watchGoals(userId);
});

final savingsByGoalStreamProvider =
    StreamProvider.family<List<SavingEntity>, String>((ref, goalId) {
  return ref.watch(goalRepositoryProvider).watchSavingsByGoal(goalId);
});

final activeGoalsProvider =
    Provider.family<List<GoalEntity>, String>((ref, userId) {
  final goals = ref.watch(goalsStreamProvider(userId)).valueOrNull ?? [];
  return goals.where((g) => !g.isCompleted).toList();
});
