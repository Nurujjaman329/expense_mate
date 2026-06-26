import 'dart:io';

import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/database/app_database.dart';
import 'package:expense_mate/core/utils/csv_export_builder.dart';
import 'package:expense_mate/core/utils/formatters.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Exports transactions to CSV and PDF files.
class ExportService {
  ExportService(this._database);

  final AppDatabase _database;

  Future<ExportResult> exportCsv(String userId) async {
    final transactions = await _database.getTransactionsByUser(userId);
    final categories = await _database.getCategoriesByUser(userId);
    final wallets = await _database.getWalletsByUser(userId);

    final categoryNames = {
      for (final c in categories) c.id: c.name,
    };
    final walletNames = {
      for (final w in wallets) w.id: w.name,
    };

    final models = transactions.map(TransactionModel.fromDrift).toList();
    final csv = CsvExportBuilder.build(
      transactions: models,
      categoryNames: categoryNames,
      walletNames: walletNames,
    );

    final file = await _writeTempFile(
      'expense_mate_transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
      csv,
    );

    return ExportResult(
      file: file,
      recordCount: models.length,
      format: ExportFormat.csv,
    );
  }

  Future<ExportResult> exportPdf(String userId) async {
    final transactions = await _database.getTransactionsByUser(userId);
    final categories = await _database.getCategoriesByUser(userId);
    final wallets = await _database.getWalletsByUser(userId);

    final categoryNames = {
      for (final c in categories) c.id: c.name,
    };
    final walletNames = {
      for (final w in wallets) w.id: w.name,
    };

    final models = transactions.map(TransactionModel.fromDrift).toList();

    double income = 0;
    double expense = 0;
    for (final tx in models) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              AppConstants.appName,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            'Transaction Report — ${Formatters.date(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Income: ${Formatters.currency(income)}'),
              pw.Text('Expense: ${Formatters.currency(expense)}'),
              pw.Text('Net: ${Formatters.currency(income - expense)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: CsvExportBuilder.headers,
            data: models.map((tx) {
              return [
                Formatters.date(tx.date),
                tx.title,
                tx.type.label,
                categoryNames[tx.categoryId] ?? tx.categoryId,
                Formatters.currency(tx.amount),
                walletNames[tx.walletId] ?? tx.walletId,
                tx.paymentMethod.label,
                tx.currency,
                tx.note ?? '',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${models.length} transactions exported',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final file = await _writeTempFile(
      'expense_mate_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      bytes,
      isBinary: true,
    );

    return ExportResult(
      file: file,
      recordCount: models.length,
      format: ExportFormat.pdf,
    );
  }

  Future<File> _writeTempFile(
    String name,
    Object content, {
    bool isBinary = false,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    if (isBinary && content is List<int>) {
      await file.writeAsBytes(content);
    } else {
      await file.writeAsString(content as String);
    }
    return file;
  }
}

enum ExportFormat { csv, pdf }

class ExportResult {
  const ExportResult({
    required this.file,
    required this.recordCount,
    required this.format,
  });

  final File file;
  final int recordCount;
  final ExportFormat format;
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(appDatabaseProvider));
});
