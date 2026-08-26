import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/activity_screen.dart';
import '../../features/transactions/presentation/new_transaction_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../widgets/main_shell.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------
abstract class AppRoutes {
  static const dashboard = '/';
  static const activity = '/activity';
  static const newTransaction = '/new-transaction';
  static const budget = '/budget';
  static const goals = '/goals';
}

// ---------------------------------------------------------------------------
// GoRouter instance
// ---------------------------------------------------------------------------
final appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    // Shell route: wraps pages that share the bottom nav / nav rail
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.activity,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.budget,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BudgetScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.goals,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GoalsScreen(),
          ),
        ),
      ],
    ),
    // Full-screen modal route (sin shell)
    GoRoute(
      path: AppRoutes.newTransaction,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const NewTransactionScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
  ],
);
