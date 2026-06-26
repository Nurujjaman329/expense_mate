import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/wallet/data/datasource/wallet_datasource.dart';
import 'package:expense_mate/features/wallet/data/models/wallet_model.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_mate/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required WalletLocalDataSource local,
    required WalletRemoteDataSource remote,
    required NetworkInfo networkInfo,
    required SyncEngine syncEngine,
  })  : _local = local,
        _remote = remote,
        _networkInfo = networkInfo,
        _syncEngine = syncEngine;

  final WalletLocalDataSource _local;
  final WalletRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SyncEngine _syncEngine;

  Future<void> saveWallet(WalletModel model) async {
    await _local.upsert(model);
    await _local.enqueueSync(model, 'create');
    if (await _networkInfo.isConnected) {
      await _syncEngine.syncAll();
    }
  }

  @override
  Stream<List<WalletEntity>> watchWallets(String userId) {
    return _local.watchWallets(userId).map((list) => list);
  }

  @override
  Future<Result<WalletEntity>> getWalletById(String id) async {
    try {
      final wallet = await _local.getById(id);
      if (wallet == null) {
        return const Error(CacheFailure(message: 'Wallet not found'));
      }
      return Success(wallet);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<WalletEntity>> createWallet(WalletEntity wallet) async {
    try {
      final model = WalletModel.fromEntity(wallet).copyWithPending();
      await saveWallet(model);
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<WalletEntity>> updateWallet(WalletEntity wallet) async {
    try {
      final model = WalletModel.fromEntity(
        wallet,
      ).copyWithUpdated(DateTime.now());
      await _local.upsert(model);
      await _local.enqueueSync(model, 'update');
      if (await _networkInfo.isConnected) await _syncEngine.syncAll();
      return Success(model);
    } catch (e) {
      return Error(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteWallet(String id) async {
    try {
      final wallet = await _local.getById(id);
      if (wallet == null) {
        return const Error(CacheFailure(message: 'Wallet not found'));
      }
      final now = DateTime.now();
      await _local.softDelete(id, now);
      await _local.enqueueSync(
        WalletModel(
          id: wallet.id,
          userId: wallet.userId,
          name: wallet.name,
          type: wallet.type,
          balance: wallet.balance,
          currency: wallet.currency,
          icon: wallet.icon,
          color: wallet.color,
          accountNumber: wallet.accountNumber,
          isDefault: wallet.isDefault,
          syncStatus: SyncStatus.pending,
          createdAt: wallet.createdAt,
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
          WalletModel(
            id: item.id,
            userId: item.userId,
            name: item.name,
            type: item.type,
            balance: item.balance,
            currency: item.currency,
            icon: item.icon,
            color: item.color,
            accountNumber: item.accountNumber,
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

  Future<void> applyBalanceChange(String walletId, double delta) async {
    final wallet = await _local.getById(walletId);
    if (wallet == null) return;
    final now = DateTime.now();
    final updated = WalletModel(
      id: wallet.id,
      userId: wallet.userId,
      name: wallet.name,
      type: wallet.type,
      balance: wallet.balance + delta,
      currency: wallet.currency,
      icon: wallet.icon,
      color: wallet.color,
      accountNumber: wallet.accountNumber,
      isDefault: wallet.isDefault,
      syncStatus: SyncStatus.pending,
      createdAt: wallet.createdAt,
      updatedAt: now,
    );
    await _local.upsert(updated);
    await _local.enqueueSync(updated, 'update');
  }
}

extension _WalletModelHelpers on WalletModel {
  WalletModel copyWithPending() {
    return WalletModel(
      id: id,
      userId: userId,
      name: name,
      type: type,
      balance: balance,
      currency: currency,
      icon: icon,
      color: color,
      accountNumber: accountNumber,
      isDefault: isDefault,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  WalletModel copyWithUpdated(DateTime updatedAt) {
    return WalletModel(
      id: id,
      userId: userId,
      name: name,
      type: type,
      balance: balance,
      currency: currency,
      icon: icon,
      color: color,
      accountNumber: accountNumber,
      isDefault: isDefault,
      syncStatus: SyncStatus.pending,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

final walletLocalDataSourceProvider = Provider<WalletLocalDataSource>((ref) {
  return WalletLocalDataSource(ref.watch(appDatabaseProvider));
});

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(ref.watch(firestoreProvider));
});

final walletRepositoryImplProvider = Provider<WalletRepositoryImpl>((ref) {
  return WalletRepositoryImpl(
    local: ref.watch(walletLocalDataSourceProvider),
    remote: ref.watch(walletRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return ref.watch(walletRepositoryImplProvider);
});

final walletsStreamProvider =
    StreamProvider.family<List<WalletEntity>, String>((ref, userId) {
  return ref.watch(walletRepositoryProvider).watchWallets(userId);
});

final totalBalanceProvider = Provider.family<double, String>((ref, userId) {
  final wallets = ref.watch(walletsStreamProvider(userId));
  return wallets.maybeWhen(
    data: (list) => list.fold(0.0, (sum, w) => sum + w.balance),
    orElse: () => 0.0,
  );
});
