import 'package:expense_mate/core/constants/app_enums.dart';
import 'package:expense_mate/core/routes/route_names.dart';
import 'package:expense_mate/features/authentication/presentation/pages/email_verification_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/login_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/onboarding_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/register_page.dart';
import 'package:expense_mate/features/authentication/presentation/pages/splash_page.dart';
import 'package:expense_mate/features/authentication/presentation/providers/auth_provider.dart';
import 'package:expense_mate/features/budget/presentation/pages/add_budget_page.dart';
import 'package:expense_mate/features/budget/presentation/pages/budgets_page.dart';
import 'package:expense_mate/features/categories/presentation/pages/categories_page.dart';
import 'package:expense_mate/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_mate/features/dashboard/presentation/pages/main_shell_page.dart';
import 'package:expense_mate/features/goals/presentation/pages/add_goal_page.dart';
import 'package:expense_mate/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:expense_mate/features/goals/presentation/pages/goals_page.dart';
import 'package:expense_mate/features/reports/presentation/pages/reports_page.dart';
import 'package:expense_mate/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:expense_mate/features/transactions/presentation/pages/transactions_page.dart';
import 'package:expense_mate/features/wallet/presentation/pages/add_wallet_page.dart';
import 'package:expense_mate/features/wallet/presentation/pages/wallets_page.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.transactions,
                builder: (context, state) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.wallets,
                builder: (context, state) => const WalletsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.reports,
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.categories,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: RouteNames.addTransaction,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final typeParam = state.uri.queryParameters['type'];
          final id = state.uri.queryParameters['id'];
          final type = typeParam != null
              ? TransactionType.values.byName(typeParam)
              : TransactionType.expense;
          return AddTransactionPage(
            transactionId: id,
            initialType: type,
          );
        },
      ),
      GoRoute(
        path: RouteNames.addWallet,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddWalletPage(),
      ),
      GoRoute(
        path: RouteNames.budgets,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BudgetsPage(),
      ),
      GoRoute(
        path: RouteNames.addBudget,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddBudgetPage(),
      ),
      GoRoute(
        path: RouteNames.goals,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: RouteNames.addGoal,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddGoalPage(),
      ),
      GoRoute(
        path: RouteNames.goalDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          if (id == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Goal ID required')),
            );
          }
          return GoalDetailPage(goalId: id);
        },
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
