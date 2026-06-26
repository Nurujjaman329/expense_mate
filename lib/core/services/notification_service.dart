import 'dart:convert';

import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/utils/logger.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';
import 'package:expense_mate/features/bills/domain/utils/bill_due_utils.dart';
import 'package:expense_mate/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_mate/features/budget/domain/entities/budget_entity.dart';
import 'package:expense_mate/features/notifications/data/models/notification_model.dart';
import 'package:expense_mate/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:expense_mate/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Generates in-app notifications from bills and budget alerts.
class NotificationService {
  NotificationService({
    required NotificationRepositoryImpl notificationRepository,
  }) : _notificationRepository = notificationRepository;

  final NotificationRepositoryImpl _notificationRepository;
  final _uuid = const Uuid();

  Future<void> refreshNotifications({
    required String userId,
    required List<BillEntity> bills,
    required List<BudgetProgress> budgetAlerts,
    required List<NotificationEntity> existing,
  }) async {
    try {
      final existingKeys = existing
          .where((n) => n.payload != null)
          .map((n) => n.payload!)
          .toSet();

      for (final bill in bills) {
        if (bill.isPaid) continue;
        if (!BillDueUtils.isDueSoon(bill) && !BillDueUtils.isOverdue(bill)) {
          continue;
        }

        final key = _payloadKey('bill', bill.id);
        if (existingKeys.contains(key)) continue;

        final days = BillDueUtils.daysUntilDue(bill);
        final body = days < 0
            ? '${bill.title} was due ${days.abs()} day(s) ago'
            : days == 0
                ? '${bill.title} is due today'
                : '${bill.title} is due in $days day(s)';

        await _notificationRepository.createNotification(
          NotificationModel(
            id: _uuid.v4(),
            userId: userId,
            title: 'Bill Reminder',
            body: body,
            type: NotificationType.billReminder,
            payload: key,
            syncStatus: SyncStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
      }

      for (final alert in budgetAlerts) {
        final key = _payloadKey('budget', alert.budget.id);
        if (existingKeys.contains(key)) continue;

        final body = alert.isOverBudget
            ? '${alert.budget.name} is over budget (${Formatters.currency(alert.spent)} spent)'
            : '${alert.budget.name} reached ${(alert.percentage * 100).toInt()}% of limit';

        await _notificationRepository.createNotification(
          NotificationModel(
            id: _uuid.v4(),
            userId: userId,
            title: 'Budget Alert',
            body: body,
            type: NotificationType.budgetAlert,
            payload: key,
            syncStatus: SyncStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.e('NotificationService', 'Failed to refresh', e, stack);
    }
  }

  String _payloadKey(String type, String entityId) {
    return jsonEncode({'type': type, 'entityId': entityId});
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    notificationRepository: ref.watch(notificationRepositoryImplProvider),
  );
});

/// Refreshes notifications when user data is loaded.
final notificationRefreshProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return;

  final bills = ref.watch(billsStreamProvider(user.id)).valueOrNull ?? [];
  final budgetAlerts = ref.watch(budgetAlertsProvider(user.id));
  final existing =
      ref.watch(notificationsStreamProvider(user.id)).valueOrNull ?? [];

  await ref.read(notificationServiceProvider).refreshNotifications(
        userId: user.id,
        bills: bills,
        budgetAlerts: budgetAlerts,
        existing: existing,
      );
});
