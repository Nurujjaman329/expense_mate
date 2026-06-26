import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/wallet/data/models/wallet_model.dart';

class WalletLocalDataSource {
  WalletLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<WalletModel>> watchWallets(String userId) {
    return _db.watchWalletsByUser(userId).map(
          (rows) => rows.map(WalletModel.fromDrift).toList(),
        );
  }

  Future<WalletModel?> getById(String id) async {
    final row = await _db.getWalletById(id);
    return row != null ? WalletModel.fromDrift(row) : null;
  }

  Future<void> upsert(WalletModel model) {
    return _db.upsertWallet(model.toCompanion());
  }

  Future<void> updateBalance(String id, double balance, DateTime updatedAt) {
    return _db.updateWalletBalance(id, balance, updatedAt);
  }

  Future<void> softDelete(String id, DateTime updatedAt) {
    return _db.softDeleteWallet(id, updatedAt);
  }

  Future<void> enqueueSync(WalletModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'wallet',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }
}

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<WalletModel>> fetchAll(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.wallets)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => WalletModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
