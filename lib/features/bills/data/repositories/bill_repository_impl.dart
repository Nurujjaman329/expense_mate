import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/bills/data/datasource/bill_datasource.dart';
import 'package:expense_mate/features/bills/data/models/bill_model.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';
import 'package:expense_mate/features/bills/domain/repositories/bill_repository.dart';
import 'package:expense_mate/features/bills/domain/utils/bill_due_utils.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl({
    required BillLocalDataSource local,
    required BillRemoteDataSource remote,
    required TransactionRepository transactionRepository,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _transactionRepository = transactionRepository,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final BillLocalDataSource _local;
  final BillRemoteDataSource _remote;
  final TransactionRepository _transactionRepository;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;
  final _uuid = const Uuid();

  Future<void> _save(BillModel model, String operation) async {
    await _local.upsert(model);
    await _local.enqueueSync(model, operation);
    if (await _networkInfo.isConnected) await _syncEngine.syncAll();
  }

  @override
  Stream<List<BillEntity>> watchBills(String userId) {
    return _local.watchBills(userId).map((list) => list);
  }

  @override
  Future<Result<BillEntity>> createBill(BillEntity bill) async {
    try {
      final now = DateTime.now();
      final model = BillModel.fromEntity(bill).copyWithPending(now);
      await _save(model, 'create');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BillEntity>> updateBill(BillEntity bill) async {
    try {
      final model =
          BillModel.fromEntity(bill).copyWithUpdated(DateTime.now());
      await _save(model, 'update');
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBill(String id) async {
    try {
      final now = DateTime.now();
      await _local.softDelete(id, now);
      await _local.enqueueSync(
        BillModel(
          id: id,
          userId: '',
          title: '',
          amount: 0,
          dueDate: now,
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
  Future<Result<BillEntity>> markAsPaid(BillEntity bill) async {
    try {
      final now = DateTime.now();

      if (bill.walletId != null && bill.categoryId != null) {
        final tx = TransactionModel(
          id: _uuid.v4(),
          userId: bill.userId,
          title: bill.title,
          amount: bill.amount,
          type: TransactionType.expense,
          walletId: bill.walletId!,
          categoryId: bill.categoryId!,
          paymentMethod: PaymentMethod.cash,
          currency: 'USD',
          date: now,
          note: 'Bill payment',
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
        );
        final txResult = await _transactionRepository.createTransaction(tx);
        if (txResult is Error) {
          return Error(txResult.failureOrNull!);
        }
      }

      BillModel updated;
      if (bill.isRecurring) {
        updated = BillModel.fromEntity(bill).copyWithUpdated(
          now,
          dueDate: BillDueUtils.advanceDueDate(bill),
          isPaid: false,
        );
      } else {
        updated = BillModel.fromEntity(bill).copyWithUpdated(
          now,
          isPaid: true,
        );
      }

      await _save(updated, 'update');
      return Success(updated);
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
          BillModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            amount: item.amount,
            categoryId: item.categoryId,
            walletId: item.walletId,
            dueDate: item.dueDate,
            isRecurring: item.isRecurring,
            recurringRule: item.recurringRule,
            isPaid: item.isPaid,
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

extension on BillModel {
  BillModel copyWithPending(DateTime now) {
    return BillModel(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      categoryId: categoryId,
      walletId: walletId,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurringRule: recurringRule,
      isPaid: isPaid,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  BillModel copyWithUpdated(
    DateTime updatedAt, {
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return BillModel(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      categoryId: categoryId,
      walletId: walletId,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring,
      recurringRule: recurringRule,
      isPaid: isPaid ?? this.isPaid,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final billLocalDataSourceProvider = Provider<BillLocalDataSource>((ref) {
  return BillLocalDataSource(ref.watch(appDatabaseProvider));
});

final billRemoteDataSourceProvider = Provider<BillRemoteDataSource>((ref) {
  return BillRemoteDataSource(ref.watch(firestoreProvider));
});

final billRepositoryImplProvider = Provider<BillRepositoryImpl>((ref) {
  return BillRepositoryImpl(
    local: ref.watch(billLocalDataSourceProvider),
    remote: ref.watch(billRemoteDataSourceProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return ref.watch(billRepositoryImplProvider);
});

final billsStreamProvider =
    StreamProvider.family<List<BillEntity>, String>((ref, userId) {
  return ref.watch(billRepositoryProvider).watchBills(userId);
});

final upcomingBillsProvider =
    Provider.family<List<BillEntity>, String>((ref, userId) {
  final bills = ref.watch(billsStreamProvider(userId)).valueOrNull ?? [];
  return BillDueUtils.upcomingUnpaid(bills);
});

final overdueBillsProvider =
    Provider.family<List<BillEntity>, String>((ref, userId) {
  final bills = ref.watch(billsStreamProvider(userId)).valueOrNull ?? [];
  return bills.where((b) => BillDueUtils.isOverdue(b)).toList();
});
