import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

/// Domain entity for recurring bills and reminders.
class BillEntity extends Equatable {
  const BillEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    this.categoryId,
    this.walletId,
    required this.dueDate,
    this.isRecurring = false,
    this.recurringRule,
    this.isPaid = false,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final double amount;
  final String? categoryId;
  final String? walletId;
  final DateTime dueDate;
  final bool isRecurring;
  final RecurringRule? recurringRule;
  final bool isPaid;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        amount,
        categoryId,
        walletId,
        dueDate,
        isRecurring,
        recurringRule,
        isPaid,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}
