import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/transactions/data/datasource/transaction_datasource.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_filter.dart';
import 'package:expense_mate/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required TransactionLocalDataSource local,
    required TransactionRemoteDataSource remote,
    required WalletRepositoryImpl walletRepository,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _walletRepository = walletRepository,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final TransactionLocalDataSource _local;
  final TransactionRemoteDataSource _remote;
  final WalletRepositoryImpl _walletRepository;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;

  @override
  Stream<List<TransactionEntity>> watchTransactions(
    String userId, {
    TransactionFilter? filter,
  }) {
    return _local.watchTransactions(userId).map((list) {
      if (filter == null) return list;
      return _local.applyFilter(list, filter);
    });
  }

  @override
  Future<Result<List<TransactionEntity>>> getRecentTransactions(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final list = await _local.getRecent(userId, limit);
      return Success(list);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<TransactionEntity>> getTransactionById(String id) async {
    try {
      final tx = await _local.getById(id);
      if (tx == null) {
        return const Error(CacheFailure(message: 'Transaction not found'));
      }
      return Success(tx);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<TransactionEntity>> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = TransactionModel.fromEntity(transaction).asPending();
      await _local.upsert(model);
      await _applyBalanceEffect(model);
      await _local.enqueueSync(model, 'create');
      if (await _networkInfo.isConnected) await _syncEngine.syncAll();
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<TransactionEntity>> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final existing = await _local.getById(transaction.id);
      if (existing != null) {
        await _reverseBalanceEffect(existing);
      }
      final model = TransactionModel.fromEntity(transaction).asPending();
      await _local.upsert(model);
      await _applyBalanceEffect(model);
      await _local.enqueueSync(model, 'update');
      if (await _networkInfo.isConnected) await _syncEngine.syncAll();
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    try {
      final existing = await _local.getById(id);
      if (existing == null) {
        return const Error(CacheFailure(message: 'Transaction not found'));
      }
      await _reverseBalanceEffect(existing);
      final now = DateTime.now();
      await _local.softDelete(id, now);
      await _local.enqueueSync(existing.copyUpdated(now), 'delete');
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
          TransactionModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            description: item.description,
            amount: item.amount,
            type: item.type,
            walletId: item.walletId,
            categoryId: item.categoryId,
            paymentMethod: item.paymentMethod,
            currency: item.currency,
            date: item.date,
            time: item.time,
            note: item.note,
            receipt: item.receipt,
            latitude: item.latitude,
            longitude: item.longitude,
            tags: item.tags,
            isRecurring: item.isRecurring,
            recurringRule: item.recurringRule,
            transferWalletId: item.transferWalletId,
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

  Future<void> _applyBalanceEffect(TransactionModel tx) async {
    switch (tx.type) {
      case TransactionType.income:
        await _walletRepository.applyBalanceChange(tx.walletId, tx.amount);
      case TransactionType.expense:
        await _walletRepository.applyBalanceChange(tx.walletId, -tx.amount);
      case TransactionType.transfer:
        await _walletRepository.applyBalanceChange(tx.walletId, -tx.amount);
        if (tx.transferWalletId != null) {
          await _walletRepository.applyBalanceChange(
            tx.transferWalletId!,
            tx.amount,
          );
        }
    }
  }

  Future<void> _reverseBalanceEffect(TransactionModel tx) async {
    switch (tx.type) {
      case TransactionType.income:
        await _walletRepository.applyBalanceChange(tx.walletId, -tx.amount);
      case TransactionType.expense:
        await _walletRepository.applyBalanceChange(tx.walletId, tx.amount);
      case TransactionType.transfer:
        await _walletRepository.applyBalanceChange(tx.walletId, tx.amount);
        if (tx.transferWalletId != null) {
          await _walletRepository.applyBalanceChange(
            tx.transferWalletId!,
            -tx.amount,
          );
        }
    }
  }
}

extension _TransactionModelOps on TransactionModel {
  TransactionModel asPending() {
    final now = DateTime.now();
    return TransactionModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      amount: amount,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      paymentMethod: paymentMethod,
      currency: currency,
      date: date,
      time: time,
      note: note,
      receipt: receipt,
      latitude: latitude,
      longitude: longitude,
      tags: tags,
      isRecurring: isRecurring,
      recurringRule: recurringRule,
      transferWalletId: transferWalletId,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  TransactionModel copyUpdated(DateTime updatedAt) {
    return TransactionModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      amount: amount,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      paymentMethod: paymentMethod,
      currency: currency,
      date: date,
      time: time,
      note: note,
      receipt: receipt,
      latitude: latitude,
      longitude: longitude,
      tags: tags,
      isRecurring: isRecurring,
      recurringRule: recurringRule,
      transferWalletId: transferWalletId,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

TransactionSummary computeSummary(List<TransactionEntity> transactions) {
  var income = 0.0;
  var expense = 0.0;
  for (final tx in transactions) {
    switch (tx.type) {
      case TransactionType.income:
        income += tx.amount;
      case TransactionType.expense:
        expense += tx.amount;
      case TransactionType.transfer:
        break;
    }
  }
  return TransactionSummary(
    totalIncome: income,
    totalExpense: expense,
    balance: income - expense,
  );
}

final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSource(ref.watch(appDatabaseProvider));
});

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSource(ref.watch(firestoreProvider));
});

final transactionRepositoryImplProvider =
    Provider<TransactionRepositoryImpl>((ref) {
  return TransactionRepositoryImpl(
    local: ref.watch(transactionLocalDataSourceProvider),
    remote: ref.watch(transactionRemoteDataSourceProvider),
    walletRepository: ref.watch(walletRepositoryImplProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return ref.watch(transactionRepositoryImplProvider);
});

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final transactionsStreamProvider =
    StreamProvider.family<List<TransactionEntity>, String>((ref, userId) {
  final filter = ref.watch(transactionFilterProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(userId, filter: filter);
});

final monthlySummaryProvider =
    Provider.family<TransactionSummary, String>((ref, userId) {
  final transactions = ref.watch(transactionsStreamProvider(userId));
  return transactions.maybeWhen(
    data: (list) {
      final now = DateTime.now();
      final monthly = list.where(
        (t) => t.date.year == now.year && t.date.month == now.month,
      );
      return computeSummary(monthly.toList());
    },
    orElse: () => const TransactionSummary(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
    ),
  );
});

final recentTransactionsProvider =
    FutureProvider.family<List<TransactionEntity>, String>((ref, userId) async {
  final result = await ref
      .watch(transactionRepositoryProvider)
      .getRecentTransactions(userId, limit: 5);
  return result.dataOrNull ?? [];
});
