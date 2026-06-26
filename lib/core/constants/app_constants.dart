/// Application-wide constants: app name, storage keys, and default values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Expense Mate';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguageCode = 'language_code';
  static const String keyCurrencyCode = 'currency_code';
  static const String keyDateFormat = 'date_format';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyPinLockEnabled = 'pin_lock_enabled';
  static const String keyPinCode = 'pin_code';

  // Defaults
  static const String defaultCurrency = 'USD';
  static const String defaultDateFormat = 'MMM dd, yyyy';
  static const String defaultLanguage = 'en';

  // Pagination
  static const int defaultPageSize = 20;

  // Sync
  static const int syncRetryMaxAttempts = 5;
  static const Duration syncRetryDelay = Duration(seconds: 30);
}
