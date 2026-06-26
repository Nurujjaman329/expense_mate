import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// PIN hashing and biometric authentication helpers.
class SecurityService {
  SecurityService(this._storage, this._localAuth);

  final LocalStorageService _storage;
  final LocalAuthentication _localAuth;

  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  bool verifyPin(String pin) {
    final stored = _storage.pinHash;
    if (stored == null) return false;
    return stored == hashPin(pin);
  }

  Future<bool> setPin(String pin) async {
    await _storage.setPinHash(hashPin(pin));
    await _storage.setPinLockEnabled(true);
    return true;
  }

  Future<void> removePin() async {
    await _storage.setPinHash(null);
    await _storage.setPinLockEnabled(false);
    await _storage.setBiometricEnabled(false);
  }

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock Expense Mate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  bool get isPinEnabled => _storage.isPinLockEnabled;

  bool get isBiometricEnabled => _storage.isBiometricEnabled;
}

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(
    ref.watch(localStorageProvider),
    ref.watch(localAuthProvider),
  );
});
