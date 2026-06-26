import 'package:drift/drift.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/data/firestore_mapper.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/features/wallet/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.balance,
    required super.currency,
    super.icon,
    super.color,
    super.accountNumber,
    super.isDefault,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory WalletModel.fromDrift(Wallet row) {
    return WalletModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: WalletType.values.byName(row.type),
      balance: row.balance,
      currency: row.currency,
      icon: row.icon,
      color: row.color,
      accountNumber: row.accountNumber,
      isDefault: row.isDefault,
      syncStatus: SyncStatus.values.byName(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  factory WalletModel.fromFirestore(String id, Map<String, dynamic> json) {
    return WalletModel(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: WalletType.values.byName(json['type'] as String),
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      icon: json['icon'] as String?,
      color: json['color'] as int?,
      accountNumber: json['accountNumber'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      syncStatus: SyncStatus.synced,
      createdAt: FirestoreMapper.parseDate(json['createdAt']),
      updatedAt: FirestoreMapper.parseDate(json['updatedAt']),
    );
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      balance: entity.balance,
      currency: entity.currency,
      icon: entity.icon,
      color: entity.color,
      accountNumber: entity.accountNumber,
      isDefault: entity.isDefault,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  WalletsCompanion toCompanion({bool? isDeleted}) {
    return WalletsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type.name),
      balance: Value(balance),
      currency: Value(currency),
      icon: Value(icon),
      color: Value(color),
      accountNumber: Value(accountNumber),
      isDefault: Value(isDefault),
      syncStatus: Value(syncStatus.name),
      isDeleted: Value(isDeleted ?? false),
      createdAt: Value(createdAt ?? DateTime.now()),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'currency': currency,
      'icon': icon,
      'color': color,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
      'isDeleted': false,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  WalletEntity toEntity() => this;
}
