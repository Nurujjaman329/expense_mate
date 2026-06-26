import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:expense_mate/core/services/security_service.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/features/settings/presentation/providers/app_lock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen PIN entry when the app is locked.
class PinLockPage extends ConsumerStatefulWidget {
  const PinLockPage({super.key});

  @override
  ConsumerState<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends ConsumerState<PinLockPage> {
  final _pinController = TextEditingController();
  String _error = '';
  bool _isVerifying = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final storage = ref.read(localStorageProvider);
    if (!storage.isBiometricEnabled) return;

    final ok =
        await ref.read(securityServiceProvider).authenticateWithBiometrics();
    if (ok && mounted) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _error = 'Enter 4-digit PIN');
      return;
    }

    setState(() => _isVerifying = true);

    final valid = ref.read(securityServiceProvider).verifyPin(pin);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (valid) {
      _pinController.clear();
      ref.read(appLockProvider.notifier).unlock();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  void _onDigit(String digit) {
    if (_pinController.text.length >= 4) return;
    _pinController.text += digit;
    setState(() => _error = '');
    if (_pinController.text.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pinController.text.isEmpty) return;
    _pinController.text =
        _pinController.text.substring(0, _pinController.text.length - 1);
    setState(() => _error = '');
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(localStorageProvider).isBiometricEnabled;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pinController.text.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppColors.primary
                          : AppColors.dividerLight,
                    ),
                  );
                }),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: AppColors.error)),
              ],
              if (_isVerifying)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
              const Spacer(),
              _PinPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
              if (biometricEnabled) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 72, height: 72);
            }
            return SizedBox(
              width: 72,
              height: 72,
              child: key == '⌫'
                  ? IconButton(
                      icon: const Icon(Icons.backspace_outlined),
                      onPressed: onBackspace,
                    )
                  : Material(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onDigit(key),
                        child: Center(
                          child: Text(
                            key,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                    ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
