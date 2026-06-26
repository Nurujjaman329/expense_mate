import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/routes/app_router.dart';
import 'package:expense_mate/core/theme/app_theme.dart';
import 'package:expense_mate/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_mate/features/settings/presentation/providers/theme_provider.dart';
import 'package:expense_mate/features/settings/presentation/widgets/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget — wires theme, localization, and GoRouter.
class ExpenseMateApp extends ConsumerWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(settingsProvider).languageCode;

    return AppLockGate(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: Locale(languageCode),
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('bn'),
        ],
      ),
    );
  }
}
