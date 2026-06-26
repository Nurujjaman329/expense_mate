import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/services/backup_service.dart';
import 'package:expense_mate/core/services/export_service.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Export transactions and backup/restore user data.
class DataManagementPage extends ConsumerStatefulWidget {
  const DataManagementPage({super.key});

  @override
  ConsumerState<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends ConsumerState<DataManagementPage> {
  bool _isExporting = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _shareFile(ExportResult result) async {
    await Share.shareXFiles(
      [XFile(result.file.path)],
      subject: 'Expense Mate ${result.format.name.toUpperCase()} Export',
      text: 'Exported ${result.recordCount} transactions',
    );
  }

  Future<void> _exportCsv() async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isExporting = true);
    try {
      final result = await ref.read(exportServiceProvider).exportCsv(userId);
      if (mounted) {
        await _shareFile(result);
        context.showAppSnackBar('CSV exported (${result.recordCount} rows)');
      }
    } catch (e) {
      if (mounted) {
        context.showAppSnackBar('CSV export failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isExporting = true);
    try {
      final result = await ref.read(exportServiceProvider).exportPdf(userId);
      if (mounted) {
        await _shareFile(result);
        context.showAppSnackBar('PDF exported (${result.recordCount} rows)');
      }
    } catch (e) {
      if (mounted) {
        context.showAppSnackBar('PDF export failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _createBackup() async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    setState(() => _isBackingUp = true);
    try {
      final file =
          await ref.read(backupServiceProvider).exportBackupFile(userId);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Expense Mate Backup',
          text: 'Full data backup JSON file',
        );
        context.showAppSnackBar('Backup created');
      }
    } catch (e) {
      if (mounted) {
        context.showAppSnackBar('Backup failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This merges backup data into your local database. '
          'Existing records with the same IDs will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (picked == null || picked.files.single.path == null) return;

    setState(() => _isRestoring = true);
    try {
      final content = await picked.files.single.xFile.readAsString();
      final result = await ref.read(backupServiceProvider).restoreFromJson(
            content,
            userId: userId,
          );

      if (mounted) {
        context.showAppSnackBar(
          result.message,
          isError: !result.success,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showAppSnackBar('Restore failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isExporting || _isBackingUp || _isRestoring;

    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Export',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.table_chart_outlined,
            title: 'Export CSV',
            subtitle: 'Spreadsheet-friendly transaction list',
            onTap: busy ? null : _exportCsv,
            isLoading: _isExporting,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export PDF',
            subtitle: 'Printable report with income/expense summary',
            onTap: busy ? null : _exportPdf,
            isLoading: _isExporting,
          ),
          const SizedBox(height: 24),
          Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Create Backup',
            subtitle: 'JSON file with wallets, transactions, budgets, goals, bills',
            onTap: busy ? null : _createBackup,
            isLoading: _isBackingUp,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.cloud_download_outlined,
            title: 'Restore Backup',
            subtitle: 'Import data from a backup JSON file',
            onTap: busy ? null : _restoreBackup,
            isLoading: _isRestoring,
            accent: AppColors.warning,
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.info.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Exports include all local transactions. Backups include '
                'wallets, categories, budgets, goals, bills, and savings. '
                'Restore merges into your device and syncs when online.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;

    return Card(
      child: ListTile(
        leading: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
