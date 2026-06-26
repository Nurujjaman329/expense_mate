import 'package:expense_mate/core/constants/app_constants.dart';
import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported app currencies.
class AppCurrency {
  const AppCurrency({required this.code, required this.symbol, required this.name});

  final String code;
  final String symbol;
  final String name;
}

const supportedCurrencies = [
  AppCurrency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
  AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
  AppCurrency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
  AppCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
];

const supportedLanguages = {
  'en': 'English',
  'bn': 'বাংলা',
};

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage)
      : super(SettingsState(
          currencyCode: _storage.currencyCode,
          languageCode: _storage.languageCode,
          biometricEnabled: _storage.isBiometricEnabled,
          pinLockEnabled: _storage.isPinLockEnabled,
        ));

  final LocalStorageService _storage;

  Future<void> setCurrency(String code) async {
    await _storage.setCurrencyCode(code);
    state = state.copyWith(currencyCode: code);
  }

  Future<void> setLanguage(String code) async {
    await _storage.setLanguageCode(code);
    state = state.copyWith(languageCode: code);
  }

  void refreshSecurityFlags() {
    state = state.copyWith(
      biometricEnabled: _storage.isBiometricEnabled,
      pinLockEnabled: _storage.isPinLockEnabled,
    );
  }
}

class SettingsState {
  const SettingsState({
    required this.currencyCode,
    required this.languageCode,
    required this.biometricEnabled,
    required this.pinLockEnabled,
  });

  final String currencyCode;
  final String languageCode;
  final bool biometricEnabled;
  final bool pinLockEnabled;

  SettingsState copyWith({
    String? currencyCode,
    String? languageCode,
    bool? biometricEnabled,
    bool? pinLockEnabled,
  }) {
    return SettingsState(
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(localStorageProvider));
});

final currencySymbolProvider = Provider<String>((ref) {
  final code = ref.watch(settingsProvider).currencyCode;
  for (final c in supportedCurrencies) {
    if (c.code == code) return c.symbol;
  }
  return AppConstants.defaultCurrency;
});
