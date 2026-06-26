import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:expense_mate/core/database/tables/bills_table.dart';
import 'package:expense_mate/core/database/tables/budgets_table.dart';
import 'package:expense_mate/core/database/tables/categories_table.dart';
import 'package:expense_mate/core/database/tables/goals_table.dart';
import 'package:expense_mate/core/database/tables/notifications_table.dart';
import 'package:expense_mate/core/database/tables/savings_table.dart';
import 'package:expense_mate/core/database/tables/sync_queue_table.dart';
import 'package:expense_mate/core/database/tables/transactions_table.dart';
import 'package:expense_mate/core/database/tables/wallets_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Main Drift database — offline cache and sync queue for all entities.
@DriftDatabase(
  tables: [
    Transactions,
    Wallets,
    Categories,
    Budgets,
    Goals,
    Savings,
    Bills,
    Notifications,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here.
        },
      );

  // --- Sync Queue ---

  Future<int> enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) {
    final now = DateTime.now();
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<SyncQueueData>> getPendingSyncItems() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  Future<void> markSyncCompleted(int queueId) {
    return (update(syncQueue)..where((q) => q.id.equals(queueId))).write(
      SyncQueueCompanion(
        status: const Value('completed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSyncFailed(int queueId, String error) {
    return (update(syncQueue)..where((q) => q.id.equals(queueId))).write(
      SyncQueueCompanion(
        status: const Value('failed'),
        errorMessage: Value(error),
        retryCount: const Value(1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Transactions ---

  Future<List<Transaction>> getTransactionsByUser(String userId) {
    return (select(transactions)
          ..where(
            (t) => t.userId.equals(userId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getPendingTransactions(String userId) {
    return (select(transactions)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.syncStatus.equals('pending') &
                t.isDeleted.equals(false),
          ))
        .get();
  }

  Future<void> upsertTransaction(TransactionsCompanion entry) {
    return into(transactions).insertOnConflictUpdate(entry);
  }

  // --- Wallets ---

  Future<List<Wallet>> getWalletsByUser(String userId) {
    return (select(wallets)
          ..where(
            (w) => w.userId.equals(userId) & w.isDeleted.equals(false),
          ))
        .get();
  }

  Future<void> upsertWallet(WalletsCompanion entry) {
    return into(wallets).insertOnConflictUpdate(entry);
  }

  // --- Categories ---

  Future<List<Category>> getCategoriesByUser(String userId) {
    return (select(categories)
          ..where(
            (c) => c.userId.equals(userId) & c.isDeleted.equals(false),
          ))
        .get();
  }

  Future<void> upsertCategory(CategoriesCompanion entry) {
    return into(categories).insertOnConflictUpdate(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'expense_mate.db'));
    return NativeDatabase.createInBackground(file);
  });
}
