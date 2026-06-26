import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/features/authentication/presentation/pages/email_verification_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/login_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/onboarding_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/register_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/splash_page.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == RouteNames.splash;
      if (isSplash) return null;

      final isAuthRoute = _isAuthRoute(state.matchedLocation);
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.isEmailVerified ?? false;

      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn &&
          !isEmailVerified &&
          state.matchedLocation != RouteNames.emailVerification) {
        return RouteNames.emailVerification;
      }

      if (isLoggedIn &&
          isEmailVerified &&
          isAuthRoute &&
          state.matchedLocation != RouteNames.onboarding) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.emailVerification,
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
    ],
  );
});

bool _isAuthRoute(String location) {
  return location == RouteNames.login ||
      location == RouteNames.register ||
      location == RouteNames.forgotPassword ||
      location == RouteNames.onboarding ||
      location == RouteNames.splash;
}
