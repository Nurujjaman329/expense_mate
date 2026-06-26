import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme mode preference (system, light, dark).
class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeNotifier(this._prefs) : super(_loadTheme(_prefs));

  final SharedPreferences _prefs;

  static ThemeModeOption _loadTheme(SharedPreferences prefs) {
    final value = prefs.getString('theme_mode') ?? 'system';
    return ThemeModeOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeModeOption.system,
    );
  }

  Future<void> setTheme(ThemeModeOption mode) async {
    state = mode;
    await _prefs.setString('theme_mode', mode.name);
  }

  ThemeMode get themeMode => switch (state) {
        ThemeModeOption.system => ThemeMode.system,
        ThemeModeOption.light => ThemeMode.light,
        ThemeModeOption.dark => ThemeMode.dark,
      };
}

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeModeOption>((ref) {
  return ThemeNotifier(ref.watch(sharedPreferencesProvider));
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeNotifierProvider.notifier).themeMode;
});
