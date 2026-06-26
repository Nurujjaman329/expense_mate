import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/bills/data/models/bill_model.dart';
import 'package:expense_mate/features/budget/data/models/budget_model.dart';
import 'package:expense_mate/features/categories/data/models/category_model.dart';
import 'package:expense_mate/features/goals/data/models/goal_model.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:expense_mate/features/wallet/data/models/wallet_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Full JSON backup and restore of local user financial data.
class BackupService {
  BackupService({
    required AppDatabase database,
    required SyncEngine syncEngine,
  })  : _database = database,
        _syncEngine = syncEngine;

  final AppDatabase _database;
  final SyncEngine _syncEngine;

  static const backupVersion = 1;

  Future<Map<String, dynamic>> createBackup(String userId) async {
    final transactions = await _database.getTransactionsByUser(userId);
    final wallets = await _database.getWalletsByUser(userId);
    final categories = await _database.getCategoriesByUser(userId);
    final budgets = await _database.getBudgetsByUser(userId);
    final goals = await _database.getGoalsByUser(userId);
    final bills = await _database.getBillsByUser(userId);
    final savings = await _database.getSavingsByUser(userId);

    return {
      'version': backupVersion,
      'app': AppConstants.appName,
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
      'transactions': transactions
          .map((r) => _withId(r.id, TransactionModel.fromDrift(r).toFirestoreMap()))
          .toList(),
      'wallets': wallets
          .map((r) => _withId(r.id, WalletModel.fromDrift(r).toFirestoreMap()))
          .toList(),
      'categories': categories
          .map((r) => _withId(r.id, CategoryModel.fromDrift(r).toFirestoreMap()))
          .toList(),
      'budgets': budgets
          .map((r) => _withId(r.id, BudgetModel.fromDrift(r).toFirestoreMap()))
          .toList(),
      'goals': goals
          .map((r) => _withId(r.id, GoalModel.fromDrift(r).toFirestoreMap()))
          .toList(),
      'bills': bills
          .map((r) => _withId(r.id, BillModel.fromDrift(r).toFirestoreMap()))
          .toList(),
      'savings': savings.map(_savingToMap).toList(),
    };
  }

  Future<File> exportBackupFile(String userId) async {
    final backup = await createBackup(userId);
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/expense_mate_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(backup));
    return file;
  }

  Future<BackupRestoreResult> restoreFromJson(
    String jsonContent, {
    required String userId,
  }) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 0;
      if (version != backupVersion) {
        return BackupRestoreResult(
          success: false,
          message: 'Unsupported backup version: $version',
        );
      }

      final backupUserId = data['userId'] as String?;
      if (backupUserId != null && backupUserId != userId) {
        return const BackupRestoreResult(
          success: false,
          message: 'Backup belongs to a different account',
        );
      }

      var restored = 0;

      for (final item in (data['categories'] as List<dynamic>? ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String;
        await _database.upsertCategory(
          CategoryModel.fromFirestore(id, map).toCompanion(),
        );
        restored++;
      }

      for (final item in (data['wallets'] as List<dynamic>? ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String;
        await _database.upsertWallet(
          WalletModel.fromFirestore(id, map).toCompanion(),
        );
        restored++;
      }

      for (final item in (data['transactions'] as List<dynamic>? ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String;
        await _database.upsertTransaction(
          TransactionModel.fromFirestore(id, map).toCompanion(),
        );
        restored++;
      }

      for (final item in (data['budgets'] as List<dynamic>? ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String;
        await _database.upsertBudget(
          BudgetModel.fromFirestore(id, map).toCompanion(),
        );
        restored++;
      }

      for (final item in (data['goals'] as List<dynamic>? ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String;
        await _database.upsertGoal(
          GoalModel.fromFirestore(id, map).toCompanion(),
        );
        restored++;
      }

      for (final item in (data['bills'] as List<dynamic>? ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map.remove('id') as String;
        await _database.upsertBill(
          BillModel.fromFirestore(id, map).toCompanion(),
        );
        restored++;
      }

      for (final item in (data['savings'] as List<dynamic>? ?? [])) {
        await _database.upsertSaving(_savingFromMap(item as Map<String, dynamic>));
        restored++;
      }

      await _syncEngine.syncAll();

      return BackupRestoreResult(
        success: true,
        message: 'Restored $restored records',
        restoredCount: restored,
      );
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        message: 'Restore failed: $e',
      );
    }
  }

  Map<String, dynamic> _withId(String id, Map<String, dynamic> data) {
    return {'id': id, ...data};
  }

  Map<String, dynamic> _savingToMap(Saving row) {
    return {
      'id': row.id,
      'userId': row.userId,
      'goalId': row.goalId,
      'name': row.name,
      'amount': row.amount,
      'currency': row.currency,
      'note': row.note,
      'createdAt': row.createdAt.toIso8601String(),
      'updatedAt': row.updatedAt.toIso8601String(),
    };
  }

  SavingsCompanion _savingFromMap(Map<String, dynamic> map) {
    return SavingsCompanion(
      id: Value(map['id'] as String),
      userId: Value(map['userId'] as String),
      goalId: Value(map['goalId'] as String?),
      name: Value(map['name'] as String),
      amount: Value((map['amount'] as num).toDouble()),
      currency: Value(map['currency'] as String? ?? 'USD'),
      note: Value(map['note'] as String?),
      syncStatus: const Value('pending'),
      isDeleted: const Value(false),
      createdAt: Value(DateTime.parse(map['createdAt'] as String)),
      updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
    );
  }
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.success,
    required this.message,
    this.restoredCount = 0,
  });

  final bool success;
  final String message;
  final int restoredCount;
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    database: ref.watch(appDatabaseProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});
