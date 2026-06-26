import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/budget/data/models/budget_model.dart';

class BudgetLocalDataSource {
  BudgetLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<BudgetModel>> watchBudgets(String userId) {
    return _db.watchBudgetsByUser(userId).map(
          (rows) => rows.map(BudgetModel.fromDrift).toList(),
        );
  }

  Future<void> upsert(BudgetModel model) {
    return _db.upsertBudget(model.toCompanion());
  }

  Future<void> softDelete(String id, DateTime updatedAt) {
    return _db.softDeleteBudget(id, updatedAt);
  }

  Future<void> enqueueSync(BudgetModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'budget',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }
}

class BudgetRemoteDataSource {
  BudgetRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<BudgetModel>> fetchAll(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.budgets)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => BudgetModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
