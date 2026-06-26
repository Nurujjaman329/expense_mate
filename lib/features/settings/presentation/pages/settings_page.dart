import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_mate/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App preferences: theme, currency, language, security, account.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: const Text('Profile'),
            subtitle: Text(ref.watch(authStateProvider).valueOrNull?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.profile),
          ),
          const Divider(),
          _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeMode.label),
            trailing: DropdownButton<ThemeModeOption>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: ThemeModeOption.values
                  .map(
                    (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                  )
                  .toList(),
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeNotifierProvider.notifier).setTheme(mode);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Currency'),
            subtitle: Text(settings.currencyCode),
            trailing: DropdownButton<String>(
              value: settings.currencyCode,
              underline: const SizedBox.shrink(),
              items: supportedCurrencies
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} (${c.symbol})'),
                    ),
                  )
                  .toList(),
              onChanged: (code) {
                if (code != null) {
                  ref.read(settingsProvider.notifier).setCurrency(code);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(supportedLanguages[settings.languageCode] ?? 'English'),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
              underline: const SizedBox.shrink(),
              items: supportedLanguages.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (code) {
                if (code != null) {
                  ref.read(settingsProvider.notifier).setLanguage(code);
                }
              },
            ),
          ),
          const Divider(),
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export & Backup'),
            subtitle: const Text('CSV, PDF, backup and restore'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.dataManagement),
          ),
          const Divider(),
          _SectionHeader(title: 'Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN & Biometric'),
            subtitle: Text(
              settings.pinLockEnabled ? 'PIN lock enabled' : 'Not configured',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push(RouteNames.security);
              ref.read(settingsProvider.notifier).refreshSecurityFlags();
            },
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(signOutUseCaseProvider).call();
                if (context.mounted) context.go(RouteNames.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
