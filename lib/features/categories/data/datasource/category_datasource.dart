import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/categories/data/models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<CategoryModel>> watchCategories(String userId) {
    return _db.watchCategoriesByUser(userId).map(
          (rows) => rows.map(CategoryModel.fromDrift).toList(),
        );
  }

  Future<List<CategoryModel>> getByType(String userId, String type) async {
    final rows = await _db.getCategoriesByType(userId, type);
    return rows.map(CategoryModel.fromDrift).toList();
  }

  Future<void> upsert(CategoryModel model) {
    return _db.upsertCategory(model.toCompanion());
  }

  Future<void> enqueueSync(CategoryModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'category',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }
}

class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<CategoryModel>> fetchAll(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.categories)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> upsert(CategoryModel model) async {
    await _firestore
        .collection(FirestoreConstants.categories)
        .doc(model.id)
        .set(
          FirestoreMapper.toFirestoreMap(model.toFirestoreMap()),
          SetOptions(merge: true),
        );
  }
}
