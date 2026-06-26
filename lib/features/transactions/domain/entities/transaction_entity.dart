import 'package:equatable/equatable.dart';
import 'package:expense_mate/core/constants/app_enums.dart';

/// Domain entity for financial transactions.
class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.walletId,
    required this.categoryId,
    required this.paymentMethod,
    required this.currency,
    required this.date,
    this.description,
    this.time,
    this.note,
    this.receipt,
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringRule,
    this.transferWalletId,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final double amount;
  final TransactionType type;
  final String walletId;
  final String categoryId;
  final PaymentMethod paymentMethod;
  final String currency;
  final DateTime date;
  final String? time;
  final String? note;
  final String? receipt;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringRule;
  final String? transferWalletId;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        amount,
        type,
        walletId,
        categoryId,
        paymentMethod,
        currency,
        date,
        time,
        note,
        receipt,
        latitude,
        longitude,
        tags,
        isRecurring,
        recurringRule,
        transferWalletId,
        syncStatus,
        createdAt,
        updatedAt,
      ];
}
