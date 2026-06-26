import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/features/bills/domain/entities/bill_entity.dart';
import 'package:expense_mate/features/bills/domain/utils/bill_due_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BillEntity bill({
    required DateTime dueDate,
    bool isPaid = false,
    bool isRecurring = false,
    RecurringRule? recurringRule,
  }) {
    return BillEntity(
      id: 'b1',
      userId: 'u1',
      title: 'Rent',
      amount: 1000,
      dueDate: dueDate,
      isPaid: isPaid,
      isRecurring: isRecurring,
      recurringRule: recurringRule,
    );
  }

  group('BillDueUtils', () {
    test('daysUntilDue calculates correctly', () {
      final reference = DateTime(2026, 6, 15);
      final b = bill(dueDate: DateTime(2026, 6, 18));
      expect(BillDueUtils.daysUntilDue(b, reference: reference), 3);
    });

    test('isOverdue returns true for past unpaid bills', () {
      final reference = DateTime(2026, 6, 15);
      final b = bill(dueDate: DateTime(2026, 6, 10));
      expect(BillDueUtils.isOverdue(b, reference: reference), isTrue);
    });

    test('isDueSoon returns true within default window', () {
      final reference = DateTime(2026, 6, 15);
      final b = bill(dueDate: DateTime(2026, 6, 17));
      expect(BillDueUtils.isDueSoon(b, reference: reference), isTrue);
    });

    test('advanceDueDate advances monthly recurring bill', () {
      final b = bill(
        dueDate: DateTime(2026, 6, 15),
        isRecurring: true,
        recurringRule: RecurringRule.monthly,
      );
      final next = BillDueUtils.advanceDueDate(b);
      expect(next, DateTime(2026, 7, 15));
    });

    test('upcomingUnpaid filters and sorts bills', () {
      final reference = DateTime(2026, 6, 15);
      final bills = [
        bill(dueDate: DateTime(2026, 6, 20)),
        bill(dueDate: DateTime(2026, 6, 10)),
        bill(dueDate: DateTime(2026, 7, 1), isPaid: true),
      ];
      final upcoming =
          BillDueUtils.upcomingUnpaid(bills, reference: reference);
      expect(upcoming.length, 2);
      expect(upcoming.first.dueDate, DateTime(2026, 6, 10));
    });
  });
}
