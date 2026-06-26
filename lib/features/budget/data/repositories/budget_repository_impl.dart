import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/budget/data/datasource/budget_datasource.dart';
import 'package:expense_mate/features/budget/data/models/budget_model.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_mate/features/budget/domain/utils/budget_spent_calculator.dart';
import 'package:expense_mate/features/reports/presentation/providers/analytics_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({
    required BudgetLocalDataSource local,
    required BudgetRemoteDataSource remote,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final BudgetLocalDataSource _local;
  final BudgetRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;

  Future<void> _save(BudgetModel model, String operation) async {
    await _local.upsert(model);
    await _local.enqueueSync(model, operation);
    if (await _networkInfo.isConnected) await _syncEngine.syncAll();
  }

  @override
  Stream<List<BudgetEntity>> watchBudgets(String userId) {
    return _local.watchBudgets(userId).map((list) => list);
  }

  @override
  Future<Result<BudgetEntity>> createBudget(BudgetEntity budget) async {
    try {
      final now = DateTime.now();
      final model = BudgetModel.fromEntity(budget).copyWithPending(now);
      await _save(model, 'create');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BudgetEntity>> updateBudget(BudgetEntity budget) async {
    try {
      final model =
          BudgetModel.fromEntity(budget).copyWithUpdated(DateTime.now());
      await _save(model, 'update');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBudget(String id) async {
    try {
      final now = DateTime.now();
      await _local.softDelete(id, now);
      await _local.enqueueSync(
        BudgetModel(
          id: id,
          userId: '',
          name: '',
          amount: 0,
          period: BudgetPeriod.monthly,
          startDate: now,
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
  Future<Result<void>> syncFromRemote(String userId) async {
    try {
      if (!await _networkInfo.isConnected) return const Success(null);
      final remote = await _remote.fetchAll(userId);
      for (final item in remote) {
        await _local.upsert(
          BudgetModel(
            id: item.id,
            userId: item.userId,
            name: item.name,
            amount: item.amount,
            period: item.period,
            categoryId: item.categoryId,
            alertThreshold: item.alertThreshold,
            alertEnabled: item.alertEnabled,
            startDate: item.startDate,
            endDate: item.endDate,
            syncStatus: SyncStatus.synced,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
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

extension on BudgetModel {
  BudgetModel copyWithPending(DateTime now) {
    return BudgetModel(
      id: id,
      userId: userId,
      name: name,
      amount: amount,
      period: period,
      categoryId: categoryId,
      alertThreshold: alertThreshold,
      alertEnabled: alertEnabled,
      startDate: startDate,
      endDate: endDate,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  BudgetModel copyWithUpdated(DateTime updatedAt) {
    return BudgetModel(
      id: id,
      userId: userId,
      name: name,
      amount: amount,
      period: period,
      categoryId: categoryId,
      alertThreshold: alertThreshold,
      alertEnabled: alertEnabled,
      startDate: startDate,
      endDate: endDate,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) {
  return BudgetLocalDataSource(ref.watch(appDatabaseProvider));
});

final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>((ref) {
  return BudgetRemoteDataSource(ref.watch(firestoreProvider));
});

final budgetRepositoryImplProvider = Provider<BudgetRepositoryImpl>((ref) {
  return BudgetRepositoryImpl(
    local: ref.watch(budgetLocalDataSourceProvider),
    remote: ref.watch(budgetRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return ref.watch(budgetRepositoryImplProvider);
});

final budgetsStreamProvider =
    StreamProvider.family<List<BudgetEntity>, String>((ref, userId) {
  return ref.watch(budgetRepositoryProvider).watchBudgets(userId);
});

final budgetProgressListProvider =
    Provider.family<List<BudgetProgress>, String>((ref, userId) {
  final budgets = ref.watch(budgetsStreamProvider(userId)).valueOrNull ?? [];
  final transactions =
      ref.watch(allTransactionsStreamProvider(userId)).valueOrNull ?? [];

  return budgets
      .map((b) => BudgetSpentCalculator.toProgress(b, transactions))
      .toList();
});

final budgetAlertsProvider =
    Provider.family<List<BudgetProgress>, String>((ref, userId) {
  return ref
      .watch(budgetProgressListProvider(userId))
      .where((p) => p.isAlertTriggered || p.isOverBudget)
      .toList();
});

final budgetProgressProvider =
    Provider.family<BudgetProgress?, ({String userId, String budgetId})>(
  (ref, params) {
    final list = ref.watch(budgetProgressListProvider(params.userId));
    for (final item in list) {
      if (item.budget.id == params.budgetId) return item;
    }
    return null;
  },
);
