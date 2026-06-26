import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

/// Domain entity for income/expense categories.
class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final String icon;
  final int color;
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
        icon,
        color,
        isDefault,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}
