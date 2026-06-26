import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:expense_mate/core/constants/app_constants.dart';
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

  Future<void> markSyncFailed(int queueId, String error) async {
    final item = await (select(syncQueue)
          ..where((q) => q.id.equals(queueId)))
        .getSingleOrNull();
    if (item == null) return;

    final nextRetry = item.retryCount + 1;
    final exhausted = nextRetry >= AppConstants.syncRetryMaxAttempts;

    await (update(syncQueue)..where((q) => q.id.equals(queueId))).write(
      SyncQueueCompanion(
        status: Value(exhausted ? 'failed' : 'pending'),
        errorMessage: Value(error),
        retryCount: Value(nextRetry),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> resetFailedSyncItems() async {
    return (update(syncQueue)..where((q) => q.status.equals('failed'))).write(
      SyncQueueCompanion(
        status: const Value('pending'),
        retryCount: const Value(0),
        errorMessage: const Value(null),
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

  Future<Transaction?> getTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<Transaction>> watchTransactionsByUser(String userId) {
    return (select(transactions)
          ..where(
            (t) => t.userId.equals(userId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getRecentTransactions(String userId, int limit) {
    return (select(transactions)
          ..where(
            (t) => t.userId.equals(userId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  Future<void> softDeleteTransaction(String id, DateTime updatedAt) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
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

  Future<Wallet?> getWalletById(String id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  Stream<List<Wallet>> watchWalletsByUser(String userId) {
    return (select(wallets)
          ..where(
            (w) => w.userId.equals(userId) & w.isDeleted.equals(false),
          )
          ..orderBy([(w) => OrderingTerm.desc(w.isDefault)]))
        .watch();
  }

  Future<void> updateWalletBalance(String id, double balance, DateTime updatedAt) {
    return (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        balance: Value(balance),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> softDeleteWallet(String id, DateTime updatedAt) {
    return (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
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

  Stream<List<Category>> watchCategoriesByUser(String userId) {
    return (select(categories)
          ..where(
            (c) => c.userId.equals(userId) & c.isDeleted.equals(false),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<List<Category>> getCategoriesByType(String userId, String type) {
    return (select(categories)
          ..where(
            (c) =>
                c.userId.equals(userId) &
                c.type.equals(type) &
                c.isDeleted.equals(false),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  Future<int> countCategories(String userId) {
    return (select(categories)
          ..where(
            (c) => c.userId.equals(userId) & c.isDeleted.equals(false),
          ))
        .get()
        .then((list) => list.length);
  }

  // --- Budgets ---

  Stream<List<Budget>> watchBudgetsByUser(String userId) {
    return (select(budgets)
          ..where(
            (b) => b.userId.equals(userId) & b.isDeleted.equals(false),
          )
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .watch();
  }

  Future<Budget?> getBudgetById(String id) {
    return (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertBudget(BudgetsCompanion entry) {
    return into(budgets).insertOnConflictUpdate(entry);
  }

  Future<void> softDeleteBudget(String id, DateTime updatedAt) {
    return (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  // --- Goals ---

  Stream<List<Goal>> watchGoalsByUser(String userId) {
    return (select(goals)
          ..where(
            (g) => g.userId.equals(userId) & g.isDeleted.equals(false),
          )
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Future<Goal?> getGoalById(String id) {
    return (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertGoal(GoalsCompanion entry) {
    return into(goals).insertOnConflictUpdate(entry);
  }

  Future<void> softDeleteGoal(String id, DateTime updatedAt) {
    return (update(goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  // --- Savings ---

  Stream<List<Saving>> watchSavingsByGoal(String goalId) {
    return (select(savings)
          ..where(
            (s) => s.goalId.equals(goalId) & s.isDeleted.equals(false),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  Future<void> upsertSaving(SavingsCompanion entry) {
    return into(savings).insertOnConflictUpdate(entry);
  }

  Future<void> softDeleteSaving(String id, DateTime updatedAt) {
    return (update(savings)..where((s) => s.id.equals(id))).write(
      SavingsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  // --- Bills ---

  Stream<List<Bill>> watchBillsByUser(String userId) {
    return (select(bills)
          ..where(
            (b) => b.userId.equals(userId) & b.isDeleted.equals(false),
          )
          ..orderBy([(b) => OrderingTerm.asc(b.dueDate)]))
        .watch();
  }

  Future<Bill?> getBillById(String id) {
    return (select(bills)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertBill(BillsCompanion entry) {
    return into(bills).insertOnConflictUpdate(entry);
  }

  Future<void> softDeleteBill(String id, DateTime updatedAt) {
    return (update(bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending'),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  // --- Notifications ---

  Stream<List<Notification>> watchNotificationsByUser(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  Future<int> countUnreadNotifications(String userId) {
    return (select(notifications)
          ..where(
            (n) => n.userId.equals(userId) & n.isRead.equals(false),
          ))
        .get()
        .then((list) => list.length);
  }

  Future<void> upsertNotification(NotificationsCompanion entry) {
    return into(notifications).insertOnConflictUpdate(entry);
  }

  Future<void> markNotificationRead(String id) {
    return (update(notifications)..where((n) => n.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }

  Future<void> markAllNotificationsRead(String userId) {
    return (update(notifications)..where((n) => n.userId.equals(userId))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }

  // --- Bulk export for backup ---

  Future<List<Budget>> getBudgetsByUser(String userId) {
    return (select(budgets)
          ..where(
            (b) => b.userId.equals(userId) & b.isDeleted.equals(false),
          ))
        .get();
  }

  Future<List<Goal>> getGoalsByUser(String userId) {
    return (select(goals)
          ..where(
            (g) => g.userId.equals(userId) & g.isDeleted.equals(false),
          ))
        .get();
  }

  Future<List<Bill>> getBillsByUser(String userId) {
    return (select(bills)
          ..where(
            (b) => b.userId.equals(userId) & b.isDeleted.equals(false),
          ))
        .get();
  }

  Future<List<Saving>> getSavingsByUser(String userId) {
    return (select(savings)
          ..where(
            (s) => s.userId.equals(userId) & s.isDeleted.equals(false),
          ))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'expense_mate.db'));
    return NativeDatabase.createInBackground(file);
  });
}
