import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/categories/data/datasource/category_datasource.dart';
import 'package:expense_mate/features/categories/data/models/category_model.dart';
import 'package:expense_mate/features/categories/domain/entities/category_entity.dart';
import 'package:expense_mate/features/categories/domain/repositories/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({
    required CategoryLocalDataSource local,
    required CategoryRemoteDataSource remote,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final CategoryLocalDataSource _local;
  final CategoryRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;

  /// Saves locally and queues Firestore sync.
  Future<void> saveCategory(CategoryModel model) async {
    await _local.upsert(model);
    await _local.enqueueSync(model, 'create');
    if (await _networkInfo.isConnected) {
      await _syncEngine.syncAll();
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories(String userId) {
    return _local.watchCategories(userId).map((list) => list);
  }

  @override
  Future<Result<List<CategoryEntity>>> getCategoriesByType(
    String userId,
    TransactionType type,
  ) async {
    try {
      final list = await _local.getByType(userId, type.name);
      return Success(list);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncFromRemote(String userId) async {
    try {
      if (!await _networkInfo.isConnected) {
        return const Success(null);
      }
      final remote = await _remote.fetchAll(userId);
      for (final item in remote) {
        await _local.upsert(
          CategoryModel(
            id: item.id,
            userId: item.userId,
            name: item.name,
            type: item.type,
            icon: item.icon,
            color: item.color,
            isDefault: item.isDefault,
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

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  return CategoryLocalDataSource(ref.watch(appDatabaseProvider));
});

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSource(ref.watch(firestoreProvider));
});

final categoryRepositoryImplProvider = Provider<CategoryRepositoryImpl>((ref) {
  return CategoryRepositoryImpl(
    local: ref.watch(categoryLocalDataSourceProvider),
    remote: ref.watch(categoryRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return ref.watch(categoryRepositoryImplProvider);
});

final categoriesStreamProvider =
    StreamProvider.family<List<CategoryEntity>, String>((ref, userId) {
  return ref.watch(categoryRepositoryProvider).watchCategories(userId);
});

final expenseCategoriesProvider =
    FutureProvider.family<List<CategoryEntity>, String>((ref, userId) async {
  final result = await ref
      .watch(categoryRepositoryProvider)
      .getCategoriesByType(userId, TransactionType.expense);
  return result.dataOrNull ?? [];
});

final incomeCategoriesProvider =
    FutureProvider.family<List<CategoryEntity>, String>((ref, userId) async {
  final result = await ref
      .watch(categoryRepositoryProvider)
      .getCategoriesByType(userId, TransactionType.income);
  return result.dataOrNull ?? [];
});
