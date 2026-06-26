import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.amount,
    required super.type,
    required super.walletId,
    required super.categoryId,
    required super.paymentMethod,
    required super.currency,
    required super.date,
    super.description,
    super.time,
    super.note,
    super.receipt,
    super.latitude,
    super.longitude,
    super.tags,
    super.isRecurring,
    super.recurringRule,
    super.transferWalletId,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory TransactionModel.fromDrift(Transaction row) {
    return TransactionModel(
      id: row.id,
      userId: row.userId,
      title: row.title,
      description: row.description,
      amount: row.amount,
      type: TransactionType.values.byName(row.type),
      walletId: row.walletId,
      categoryId: row.categoryId,
      paymentMethod: PaymentMethod.values.byName(row.paymentMethod),
      currency: row.currency,
      date: row.date,
      time: row.time,
      note: row.note,
      receipt: row.receipt,
      latitude: row.latitude,
      longitude: row.longitude,
      tags: row.tags?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      isRecurring: row.isRecurring,
      recurringRule: row.recurringRule,
      transferWalletId: row.transferWalletId,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory TransactionModel.fromFirestore(String id, Map<String, dynamic> json) {
    return TransactionModel(
      id: id,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      walletId: json['walletId'] as String,
      categoryId: json['categoryId'] as String? ?? '',
      paymentMethod:
          PaymentMethod.values.byName(json['paymentMethod'] as String),
      currency: json['currency'] as String? ?? 'USD',
      date: FirestoreMapper.parseDate(json['date']) ?? DateTime.now(),
      time: json['time'] as String?,
      note: json['note'] as String?,
      receipt: json['receipt'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringRule: json['recurringRule'] as String?,
      transferWalletId: json['transferWalletId'] as String?,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      description: entity.description,
      amount: entity.amount,
      type: entity.type,
      walletId: entity.walletId,
      categoryId: entity.categoryId,
      paymentMethod: entity.paymentMethod,
      currency: entity.currency,
      date: entity.date,
      time: entity.time,
      note: entity.note,
      receipt: entity.receipt,
      latitude: entity.latitude,
      longitude: entity.longitude,
      tags: entity.tags,
      isRecurring: entity.isRecurring,
      recurringRule: entity.recurringRule,
      transferWalletId: entity.transferWalletId,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TransactionsCompanion toCompanion({bool isDeleted = false}) {
    return TransactionsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: Value(description),
      amount: Value(amount),
      type: Value(type.name),
      walletId: Value(walletId),
      categoryId: Value(categoryId),
      paymentMethod: Value(paymentMethod.name),
      currency: Value(currency),
      date: Value(date),
      time: Value(time),
      note: Value(note),
      receipt: Value(receipt),
      latitude: Value(latitude),
      longitude: Value(longitude),
      tags: Value(tags.join(',')),
      isRecurring: Value(isRecurring),
      recurringRule: Value(recurringRule),
      transferWalletId: Value(transferWalletId),
      syncStatus: Value(syncStatus.name),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.name,
      'walletId': walletId,
      'categoryId': categoryId,
      'paymentMethod': paymentMethod.name,
      'currency': currency,
      'date': date.toIso8601String(),
      'time': time,
      'note': note,
      'receipt': receipt,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurringRule': recurringRule,
      'transferWalletId': transferWalletId,
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  TransactionEntity toEntity() => this;
}
