import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  Stream<List<WalletEntity>> watchWallets(String userId);

  Future<Result<WalletEntity>> getWalletById(String id);

  Future<Result<WalletEntity>> createWallet(WalletEntity wallet);

  Future<Result<WalletEntity>> updateWallet(WalletEntity wallet);

  Future<Result<void>> deleteWallet(String id);

  Future<Result<void>> syncFromRemote(String userId);
}
