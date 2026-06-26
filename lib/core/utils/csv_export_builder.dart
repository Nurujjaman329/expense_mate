import 'package:expense_mate/features/transactions/domain/entities/transaction_entity.dart';

/// Builds CSV content from transaction rows.
class CsvExportBuilder {
  CsvExportBuilder._();

  static const headers = [
    'Date',
    'Title',
    'Type',
    'Category',
    'Amount',
    'Wallet',
    'Payment Method',
    'Currency',
    'Note',
  ];

  static String build({
    required List<TransactionEntity> transactions,
    required Map<String, String> categoryNames,
    required Map<String, String> walletNames,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escape).join(','));

    for (final tx in transactions) {
      buffer.writeln([
        tx.date.toIso8601String().split('T').first,
        tx.title,
        tx.type.label,
        categoryNames[tx.categoryId] ?? tx.categoryId,
        tx.amount.toStringAsFixed(2),
        walletNames[tx.walletId] ?? tx.walletId,
        tx.paymentMethod.label,
        tx.currency,
        tx.note ?? '',
      ].map(_escape).join(','));
    }

    return buffer.toString();
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
