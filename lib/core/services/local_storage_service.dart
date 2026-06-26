import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local key-value storage for app preferences and onboarding state.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  bool get isOnboardingCompleted =>
      _prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;

  Future<bool> setOnboardingCompleted(bool value) =>
      _prefs.setBool(AppConstants.keyOnboardingCompleted, value);

  String get themeMode =>
      _prefs.getString(AppConstants.keyThemeMode) ?? 'system';

  Future<bool> setThemeMode(String value) =>
      _prefs.setString(AppConstants.keyThemeMode, value);

  String get currencyCode =>
      _prefs.getString(AppConstants.keyCurrencyCode) ??
      AppConstants.defaultCurrency;

  Future<bool> setCurrencyCode(String value) =>
      _prefs.setString(AppConstants.keyCurrencyCode, value);

  String get languageCode =>
      _prefs.getString(AppConstants.keyLanguageCode) ??
      AppConstants.defaultLanguage;

  Future<bool> setLanguageCode(String value) =>
      _prefs.setString(AppConstants.keyLanguageCode, value);

  bool get isBiometricEnabled =>
      _prefs.getBool(AppConstants.keyBiometricEnabled) ?? false;

  Future<bool> setBiometricEnabled(bool value) =>
      _prefs.setBool(AppConstants.keyBiometricEnabled, value);
}

/// Must be overridden in [bootstrap] before the app runs.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialized in bootstrap()',
  );
});

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPreferencesProvider));
});
