import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/settings/presentation/pages/pin_lock_page.dart';
import 'package:expense_mate/features/settings/presentation/providers/app_lock_provider.dart';
import 'package:expense_mate/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Locks the app on resume and shows [PinLockPage] when locked.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);

    final user = ref.watch(authStateProvider).valueOrNull;
    final isLocked = ref.watch(appLockProvider);
    final pinEnabled = ref.watch(isAppLockEnabledProvider);

    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (user != null && pinEnabled && isLocked)
          const Positioned.fill(child: PinLockPage()),
      ],
    );
  }
}
