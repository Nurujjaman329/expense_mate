import 'package:expense_mate/core/extensions/context_extensions.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/core/theme/app_colors.dart';
import 'package:expense_mate/core/widgets/app_button.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Prompts users to verify email before accessing the app.
class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _isChecking = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    await ref.read(authControllerProvider.notifier).reloadUser();
    ref.invalidate(authStateProvider);
    setState(() => _isChecking = false);

    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user?.isEmailVerified ?? false) {
      context.go(RouteNames.dashboard);
    } else {
      context.showAppSnackBar(
        'Email not verified yet. Please check your inbox.',
        isError: true,
      );
    }
  }

  Future<void> _resendEmail() async {
    final success =
        await ref.read(authControllerProvider.notifier).sendEmailVerification();
    if (mounted) {
      context.showAppSnackBar(
        success
            ? 'Verification email sent!'
            : 'Failed to send verification email',
        isError: !success,
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(signOutUseCaseProvider).call();
    if (mounted) context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to\n${user?.email ?? 'your email'}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'I\'ve Verified My Email',
                isLoading: _isChecking || isLoading,
                onPressed: _checkVerification,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isLoading ? null : _resendEmail,
                child: const Text('Resend Email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
