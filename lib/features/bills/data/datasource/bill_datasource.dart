import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/bills/data/models/bill_model.dart';

class BillLocalDataSource {
  BillLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<BillModel>> watchBills(String userId) {
    return _db.watchBillsByUser(userId).map(
          (rows) => rows.map(BillModel.fromDrift).toList(),
        );
  }

  Future<void> upsert(BillModel model) {
    return _db.upsertBill(model.toCompanion());
  }

  Future<void> softDelete(String id, DateTime updatedAt) {
    return _db.softDeleteBill(id, updatedAt);
  }

  Future<void> enqueueSync(BillModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'bill',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }
}

class BillRemoteDataSource {
  BillRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<BillModel>> fetchAll(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.bills)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => BillModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
