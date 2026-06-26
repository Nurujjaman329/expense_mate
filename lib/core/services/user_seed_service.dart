import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/constants/category_defaults.dart';
import 'package:expense_mate/core/constants/wallet_defaults.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/core/utils/logger.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/categories/data/models/category_model.dart';
import 'package:expense_mate/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:expense_mate/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_mate/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_mate/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:expense_mate/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:expense_mate/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_mate/features/wallet/data/models/wallet_model.dart';
import 'package:expense_mate/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Seeds default categories and a cash wallet for new users.
class UserSeedService {
  UserSeedService({
    required CategoryRepositoryImpl categoryRepository,
    required WalletRepositoryImpl walletRepository,
    required AppDatabase database,
  })  : _categoryRepository = categoryRepository,
        _walletRepository = walletRepository,
        _database = database;

  final CategoryRepositoryImpl _categoryRepository;
  final WalletRepositoryImpl _walletRepository;
  final AppDatabase _database;
  final _uuid = const Uuid();

  Future<void> initializeUserData(String userId) async {
    await _seedCategories(userId);
    await _seedDefaultWallet(userId);
  }

  Future<void> _seedCategories(String userId) async {
    final count = await _database.countCategories(userId);
    if (count > 0) return;

    AppLogger.i('UserSeed', 'Seeding default categories for $userId');
    final now = DateTime.now();

    for (final item in CategoryDefaults.incomeCategories) {
      await _categoryRepository.saveCategory(
        CategoryModel(
          id: _uuid.v4(),
          userId: userId,
          name: item['name'] as String,
          type: TransactionType.income,
          icon: item['icon'] as String,
          color: item['color'] as int,
          isDefault: true,
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    for (final item in CategoryDefaults.expenseCategories) {
      await _categoryRepository.saveCategory(
        CategoryModel(
          id: _uuid.v4(),
          userId: userId,
          name: item['name'] as String,
          type: TransactionType.expense,
          icon: item['icon'] as String,
          color: item['color'] as int,
          isDefault: true,
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> _seedDefaultWallet(String userId) async {
    final wallets = await _database.getWalletsByUser(userId);
    if (wallets.isNotEmpty) return;

    AppLogger.i('UserSeed', 'Seeding default wallet for $userId');
    final now = DateTime.now();

    await _walletRepository.saveWallet(
      WalletModel(
        id: _uuid.v4(),
        userId: userId,
        name: WalletDefaults.defaultWalletName,
        type: WalletDefaults.defaultWalletType,
        balance: 0,
        currency: 'USD',
        icon: WalletDefaults.defaultIcon,
        color: WalletDefaults.defaultColor,
        isDefault: true,
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

final userSeedServiceProvider = Provider<UserSeedService>((ref) {
  return UserSeedService(
    database: ref.watch(appDatabaseProvider),
    categoryRepository: ref.watch(categoryRepositoryImplProvider),
    walletRepository: ref.watch(walletRepositoryImplProvider),
  );
});

/// Initializes user data and triggers sync when authenticated.
final userDataInitializerProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;

  await ref.read(userSeedServiceProvider).initializeUserData(user.id);
  await ref.read(categoryRepositoryProvider).syncFromRemote(user.id);
  await ref.read(walletRepositoryProvider).syncFromRemote(user.id);
  await ref.read(transactionRepositoryProvider).syncFromRemote(user.id);
  await ref.read(budgetRepositoryProvider).syncFromRemote(user.id);
  await ref.read(goalRepositoryProvider).syncFromRemote(user.id);
  await ref.read(billRepositoryProvider).syncFromRemote(user.id);
  await ref.read(notificationRepositoryProvider).syncFromRemote(user.id);
  ref.read(syncEngineProvider).syncAll();
});
