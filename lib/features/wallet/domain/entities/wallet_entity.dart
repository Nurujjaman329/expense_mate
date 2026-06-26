import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

/// Domain entity for user wallet accounts.
class WalletEntity extends Equatable {
  const WalletEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.icon,
    this.color,
    this.accountNumber,
    this.isDefault = false,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final double balance;
  final String currency;
  final String? icon;
  final int? color;
  final String? accountNumber;
  final bool isDefault;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        balance,
        currency,
        icon,
        color,
        accountNumber,
        isDefault,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}
