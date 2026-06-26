import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:expense_mate/core/services/security_service.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/settings/presentation/providers/app_lock_provider.dart';
import 'package:expense_mate/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configure PIN lock and biometric unlock.
class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _biometricAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available =
        await ref.read(securityServiceProvider).canUseBiometrics();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setPin() async {
    final pin = _pinController.text;
    final confirm = _confirmPinController.text;

    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      context.showAppSnackBar('PIN must be 4 digits', isError: true);
      return;
    }
    if (pin != confirm) {
      context.showAppSnackBar('PINs do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await ref.read(securityServiceProvider).setPin(pin);
    ref.read(settingsProvider.notifier).refreshSecurityFlags();
    if (mounted) {
      setState(() => _isLoading = false);
      _pinController.clear();
      _confirmPinController.clear();
      context.showAppSnackBar('PIN lock enabled');
    }
  }

  Future<void> _disablePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable PIN Lock'),
        content: const Text('Remove PIN and biometric unlock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(securityServiceProvider).removePin();
    ref.read(appLockProvider.notifier).unlock();
    ref.read(settingsProvider.notifier).refreshSecurityFlags();
    if (mounted) context.showAppSnackBar('PIN lock disabled');
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final storage = ref.read(localStorageProvider);
    if (!storage.isPinLockEnabled) {
      context.showAppSnackBar('Enable PIN lock first', isError: true);
      return;
    }
    if (!_biometricAvailable) {
      context.showAppSnackBar('Biometrics not available', isError: true);
      return;
    }

    if (enabled) {
      final ok =
          await ref.read(securityServiceProvider).authenticateWithBiometrics();
      if (!ok) {
        if (mounted) {
          context.showAppSnackBar('Biometric verification failed', isError: true);
        }
        return;
      }
    }

    await storage.setBiometricEnabled(enabled);
    ref.read(settingsProvider.notifier).refreshSecurityFlags();
    if (mounted) {
      context.showAppSnackBar(
        enabled ? 'Biometric unlock enabled' : 'Biometric unlock disabled',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('PIN Lock'),
              subtitle: Text(
                settings.pinLockEnabled
                    ? 'App locks when backgrounded'
                    : 'Protect app with a 4-digit PIN',
              ),
              value: settings.pinLockEnabled,
              onChanged: (enabled) {
                if (!enabled) {
                  _disablePin();
                }
              },
            ),
          ),
          if (!settings.pinLockEnabled) ...[
            const SizedBox(height: 24),
            Text(
              'Set a 4-digit PIN',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _pinController,
              label: 'PIN',
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmPinController,
              label: 'Confirm PIN',
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Enable PIN Lock',
              isLoading: _isLoading,
              onPressed: _setPin,
            ),
          ],
          if (settings.pinLockEnabled) ...[
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Biometric Unlock'),
                subtitle: Text(
                  _biometricAvailable
                      ? 'Use fingerprint or Face ID'
                      : 'Not available on this device',
                ),
                value: settings.biometricEnabled && _biometricAvailable,
                onChanged: _biometricAvailable ? _toggleBiometric : null,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _disablePin,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Remove PIN Lock'),
            ),
          ],
        ],
      ),
    );
  }
}
