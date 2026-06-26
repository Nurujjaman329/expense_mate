import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the app is locked behind PIN/biometric.
class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier(this._ref) : super(false) {
    _init();
  }

  final Ref _ref;

  void _init() {
    final storage = _ref.read(localStorageProvider);
    if (storage.isPinLockEnabled) {
      state = true;
    }
  }

  void lock() {
    final storage = _ref.read(localStorageProvider);
    if (storage.isPinLockEnabled) {
      state = true;
    }
  }

  void unlock() => state = false;
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier(ref);
});

final isAppLockEnabledProvider = Provider<bool>((ref) {
  return ref.watch(localStorageProvider).isPinLockEnabled;
});
