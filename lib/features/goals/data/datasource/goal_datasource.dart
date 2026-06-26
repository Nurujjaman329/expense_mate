import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/goals/data/models/goal_model.dart';

class GoalLocalDataSource {
  GoalLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<GoalModel>> watchGoals(String userId) {
    return _db.watchGoalsByUser(userId).map(
          (rows) => rows.map(GoalModel.fromDrift).toList(),
        );
  }

  Stream<List<SavingModel>> watchSavingsByGoal(String goalId) {
    return _db.watchSavingsByGoal(goalId).map(
          (rows) => rows.map(SavingModel.fromDrift).toList(),
        );
  }

  Future<void> upsertGoal(GoalModel model) {
    return _db.upsertGoal(model.toCompanion());
  }

  Future<void> softDeleteGoal(String id, DateTime updatedAt) {
    return _db.softDeleteGoal(id, updatedAt);
  }

  Future<void> upsertSaving(SavingModel model) {
    return _db.upsertSaving(model.toCompanion());
  }

  Future<void> enqueueGoalSync(GoalModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'goal',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }

  Future<void> enqueueSavingSync(SavingModel model, String operation) {
    return _db.enqueueSync(
      entityType: 'saving',
      entityId: model.id,
      operation: operation,
      payload: jsonEncode(model.toFirestoreMap()),
    );
  }
}

class GoalRemoteDataSource {
  GoalRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<GoalModel>> fetchGoals(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.goals)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => GoalModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<SavingModel>> fetchSavings(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.savings)
        .where(FirestoreConstants.userId, isEqualTo: userId)
        .where(FirestoreConstants.isDeleted, isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => SavingModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
