import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';

/// Helpers for bill due dates and recurring schedules.
class BillDueUtils {
  BillDueUtils._();

  static int daysUntilDue(BillEntity bill, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    return due.difference(today).inDays;
  }

  static bool isOverdue(BillEntity bill, {DateTime? reference}) {
    if (bill.isPaid) return false;
    return daysUntilDue(bill, reference: reference) < 0;
  }

  static bool isDueSoon(
    BillEntity bill, {
    DateTime? reference,
    int withinDays = 3,
  }) {
    if (bill.isPaid) return false;
    final days = daysUntilDue(bill, reference: reference);
    return days >= 0 && days <= withinDays;
  }

  static DateTime advanceDueDate(BillEntity bill) {
    final rule = bill.recurringRule ?? RecurringRule.monthly;
    return switch (rule) {
      RecurringRule.weekly => bill.dueDate.add(const Duration(days: 7)),
      RecurringRule.monthly => DateTime(
          bill.dueDate.year,
          bill.dueDate.month + 1,
          bill.dueDate.day,
        ),
      RecurringRule.yearly => DateTime(
          bill.dueDate.year + 1,
          bill.dueDate.month,
          bill.dueDate.day,
        ),
    };
  }

  static List<BillEntity> upcomingUnpaid(
    List<BillEntity> bills, {
    DateTime? reference,
    int withinDays = 7,
  }) {
    return bills
        .where((b) => !b.isPaid && daysUntilDue(b, reference: reference) <= withinDays)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
}
