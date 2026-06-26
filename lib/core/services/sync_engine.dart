import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/core/network/network_info.dart';
import 'package:expense_mate/core/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offline-first sync engine: pushes pending SQLite data to Firestore.
class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required FirebaseFirestore firestore,
    required NetworkInfo networkInfo,
  })  : _database = database,
        _firestore = firestore,
        _networkInfo = networkInfo;

  final AppDatabase _database;
  final FirebaseFirestore _firestore;
  final NetworkInfo _networkInfo;
  bool _isSyncing = false;

  void startListening() {
    _networkInfo.onConnectivityChanged.listen((results) async {
      final connected = !results.contains(ConnectivityResult.none);
      if (connected) {
        await syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;

    final connected = await _networkInfo.isConnected;
    if (!connected) return;

    _isSyncing = true;
    AppLogger.i('SyncEngine', 'Starting sync...');

    try {
      final pendingItems = await _database.getPendingSyncItems();
      for (final item in pendingItems) {
        await _processSyncItem(item);
      }
    } catch (e, stack) {
      AppLogger.e('SyncEngine', 'Sync failed', e, stack);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processSyncItem(SyncQueueData item) async {
    try {
      if (item.retryCount >= AppConstants.syncRetryMaxAttempts) {
        await _database.markSyncFailed(item.id, 'Max retries exceeded');
        return;
      }

      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final collection = _collectionForEntity(item.entityType);
      final docRef = _firestore.collection(collection).doc(item.entityId);

      switch (item.operation) {
        case 'create':
        case 'update':
          await _upsertWithConflictResolution(docRef, payload);
        case 'delete':
          await docRef.update({
            FirestoreConstants.isDeleted: true,
            FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
          });
      }

      await _database.markSyncCompleted(item.id);
      AppLogger.d('SyncEngine', 'Synced ${item.entityType}/${item.entityId}');
    } catch (e) {
      await _database.markSyncFailed(item.id, e.toString());
      AppLogger.e('SyncEngine', 'Failed to sync item ${item.id}', e);
    }
  }

  Future<void> _upsertWithConflictResolution(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> localData,
  ) async {
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        ...localData,
        FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    final remoteData = snapshot.data()!;
    final remoteUpdatedAt =
        _parseTimestamp(remoteData[FirestoreConstants.updatedAt]);
    final localUpdatedAt =
        _parseTimestamp(localData[FirestoreConstants.updatedAt]);

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      await docRef.update({
        ...localData,
        FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      AppLogger.d('SyncEngine', 'Remote wins for ${docRef.id}');
    }
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _collectionForEntity(String entityType) {
    return switch (entityType) {
      'transaction' => FirestoreConstants.transactions,
      'wallet' => FirestoreConstants.wallets,
      'category' => FirestoreConstants.categories,
      'budget' => FirestoreConstants.budgets,
      'goal' => FirestoreConstants.goals,
      'saving' => FirestoreConstants.savings,
      'bill' => FirestoreConstants.bills,
      'notification' => FirestoreConstants.notifications,
      _ => throw ArgumentError('Unknown entity type: $entityType'),
    };
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    database: ref.watch(appDatabaseProvider),
    firestore: ref.watch(firestoreProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
  engine.startListening();
  return engine;
});
