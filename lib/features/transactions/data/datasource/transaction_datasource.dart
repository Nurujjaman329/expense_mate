import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_filter.dart';
import 'package:expense_mate/features/transactions/domain/utils/transaction_filter_utils.dart';

class TransactionLocalDataSource {
  TransactionLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _db.watchTransactionsByUser(userId).map(
          (rows) => rows.map(TransactionModel.fromDrift).toList(),
        );
  }

  Future<List<TransactionModel>> getRecent(String userId, int limit) async {
    final rows = await _db.getRecentTransactions(userId, limit);
    return rows.map(TransactionModel.fromDrift).toList();
  }

  Future<TransactionModel?> getById(String id) async {
    final row = await _db.getTransactionById(id);
    return row != null ? TransactionModel.fromDrift(row) : null;
  }

  Future<void> upsert(TransactionModel model) {
    return _db.upsertTransaction(model.toCompanion());
  }

  Future<void> softDelete(String id, DateTime updatedAt) {
    return _db.softDeleteTransaction(id, updatedAt);
  }

  Future<void> enqueueSync(TransactionModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'transaction',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }

  List<TransactionModel> applyFilter(
    List<TransactionModel> items,
    TransactionFilter filter,
  ) {
    return TransactionFilterUtils.apply(items, filter);
  }
}

class TransactionRemoteDataSource {
  TransactionRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<TransactionModel>> fetchAll(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.transactions)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
