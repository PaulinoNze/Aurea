import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

// ---------------------------------------------------------------------------
// Modelo de progreso de meta (calculado en memoria, no en Drift)
// ---------------------------------------------------------------------------

class GoalProgress {
  final SavingsGoal goal;
  final double currentContributed; // suma de aportes en goal_contributions
  final double progress; // 0.0–1.0
  final double? monthlySavingsNeeded; // null si no hay deadline
  final int? daysRemaining; // null si no hay deadline
  final bool isCompleted;

  const GoalProgress({
    required this.goal,
    required this.currentContributed,
    required this.progress,
    this.monthlySavingsNeeded,
    this.daysRemaining,
    required this.isCompleted,
  });
}

class DebtProgress {
  final Debt debt;
  final double totalPaid; // suma de pagos en debt_payments
  final double effectiveRemaining; // debt.remainingAmount - totalPaid
  final bool isPaidOff;

  const DebtProgress({
    required this.debt,
    required this.totalPaid,
    required this.effectiveRemaining,
    required this.isPaidOff,
  });
}

// ---------------------------------------------------------------------------
// Modelo de gasto por categoría
// ---------------------------------------------------------------------------

class CategoryExpense {
  final int categoryId;
  final String name;
  final double amount;
  final double percentage;
  final int iconCode;
  final Color color;

  const CategoryExpense({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.iconCode,
    required this.color,
  });
}

Color _parseHex(String hex) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF919095);
}

// ---------------------------------------------------------------------------
// Providers base — Streams de Drift
// ---------------------------------------------------------------------------

/// Todas las categorías
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

/// Todas las transacciones (sin límite, orden desc)
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTransactions();
});

/// Últimas 50 transacciones (para actividad reciente)
final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentTransactions(limit: 50);
});

/// Ingresos del mes actual
final monthlyIncomeProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db.watchMonthlyIncome(now.year, now.month);
});

/// Gastos del mes actual
final monthlyExpensesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db.watchMonthlyExpenses(now.year, now.month);
});

/// TOTAL histórico de ingresos (all-time)
final totalIncomeProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalIncome();
});

/// TOTAL histórico de gastos (all-time)
final totalExpensesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalExpenses();
});

/// Patrimonio neto = ingresos totales − gastos totales (reactivo)
final netWorthProvider = StreamProvider<double>((ref) async* {
  final db = ref.watch(databaseProvider);
  await for (final income in db.watchTotalIncome()) {
    final expenses = await db.watchTotalExpenses().first;
    yield income - expenses;
  }
});

/// Todos los presupuestos
final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBudgets();
});

/// Suma total de límites de presupuesto
final totalBudgetLimitProvider = StreamProvider<double>((ref) async* {
  final db = ref.watch(databaseProvider);
  await for (final budgetList in db.watchAllBudgets()) {
    yield budgetList.fold<double>(0.0, (sum, b) => sum + b.amount);
  }
});

/// Todas las metas de ahorro
final goalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllGoals();
});

/// Todos los aportes a metas de ahorro
final goalContributionsProvider = StreamProvider<List<GoalContribution>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllGoalContributions();
});

/// Todas las deudas (ordenadas por APR desc para método avalancha)
final debtsProvider = StreamProvider<List<Debt>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDebts();
});

/// Todos los pagos a deudas
final debtPaymentsProvider = StreamProvider<List<DebtPayment>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDebtPayments();
});

// ---------------------------------------------------------------------------
// Provider derivado — Gastos por categoría (mes actual)
// ---------------------------------------------------------------------------

final categoryExpensesProvider =
    StreamProvider<List<CategoryExpense>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();

  await for (final txs in db.watchTransactionsByMonth(now.year, now.month)) {
    final catList = await db.getAllCategories();
    final catMap = {for (final c in catList) c.id: c};

    final amountMap = <int, double>{};
    double totalExpenses = 0.0;

    for (final tx in txs.where((t) => t.type == 'expense')) {
      amountMap[tx.categoryId] = (amountMap[tx.categoryId] ?? 0) + tx.amount;
      totalExpenses += tx.amount;
    }

    final result = <CategoryExpense>[];
    amountMap.forEach((catId, amount) {
      final cat = catMap[catId];
      if (cat != null && amount > 0) {
        result.add(CategoryExpense(
          categoryId: catId,
          name: cat.name,
          amount: amount,
          percentage: totalExpenses > 0 ? amount / totalExpenses : 0,
          iconCode: cat.iconCode,
          color: _parseHex(cat.colorHex),
        ));
      }
    });

    result.sort((a, b) => b.amount.compareTo(a.amount));
    yield result;
  }
});

// ---------------------------------------------------------------------------
// Provider derivado — Progreso de metas (basado en aportes reales)
// ---------------------------------------------------------------------------

final goalsProgressProvider = Provider<AsyncValue<List<GoalProgress>>>((ref) {
  final goalsAsync = ref.watch(goalsProvider);
  final contribsAsync = ref.watch(goalContributionsProvider);

  return goalsAsync.when(
    data: (goals) {
      return contribsAsync.when(
        data: (contributions) {
          final contribMap = <int, double>{};
          for (final c in contributions) {
            contribMap[c.goalId] = (contribMap[c.goalId] ?? 0) + c.amount;
          }

          final now = DateTime.now();

          final result = goals.map((goal) {
            final contributed = contribMap[goal.id] ?? 0.0;
            final progress = goal.targetAmount > 0
                ? (contributed / goal.targetAmount).clamp(0.0, 1.0)
                : 0.0;
            final isCompleted =
                contributed >= goal.targetAmount && goal.targetAmount > 0;

            double? monthlySavingsNeeded;
            int? daysRemaining;

            if (goal.deadline != null && goal.deadline!.isAfter(now)) {
              daysRemaining = goal.deadline!.difference(now).inDays;
              final monthsRemaining = daysRemaining / 30.0;
              final remaining =
                  (goal.targetAmount - contributed).clamp(0.0, double.infinity);
              monthlySavingsNeeded =
                  monthsRemaining > 0 ? remaining / monthsRemaining : remaining;
            }

            return GoalProgress(
              goal: goal,
              currentContributed: contributed,
              progress: progress,
              monthlySavingsNeeded: monthlySavingsNeeded,
              daysRemaining: daysRemaining,
              isCompleted: isCompleted,
            );
          }).toList();

          return AsyncValue.data(result);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Metas activas (no completadas)
final activeGoalsProgressProvider =
    Provider<AsyncValue<List<GoalProgress>>>((ref) {
  final progressAsync = ref.watch(goalsProgressProvider);
  return progressAsync.whenData((all) => all.where((gp) => !gp.isCompleted).toList());
});

// ---------------------------------------------------------------------------
// Provider derivado — Progreso de deudas (basado en pagos reales)
// ---------------------------------------------------------------------------

final debtsProgressProvider = Provider<AsyncValue<List<DebtProgress>>>((ref) {
  final debtsAsync = ref.watch(debtsProvider);
  final paymentsAsync = ref.watch(debtPaymentsProvider);

  return debtsAsync.when(
    data: (debts) {
      return paymentsAsync.when(
        data: (payments) {
          final payMap = <int, double>{};
          for (final p in payments) {
            payMap[p.debtId] = (payMap[p.debtId] ?? 0) + p.amount;
          }

          final result = debts.map((debt) {
            final totalPaid = payMap[debt.id] ?? 0.0;
            final effectiveRemaining =
                (debt.remainingAmount - totalPaid).clamp(0.0, double.infinity);
            final isPaidOff = effectiveRemaining <= 0;

            return DebtProgress(
              debt: debt,
              totalPaid: totalPaid,
              effectiveRemaining: effectiveRemaining,
              isPaidOff: isPaidOff,
            );
          }).toList();

          return AsyncValue.data(result);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Deudas activas (con saldo pendiente > 0)
final activeDebtsProgressProvider =
    Provider<AsyncValue<List<DebtProgress>>>((ref) {
  final progressAsync = ref.watch(debtsProgressProvider);
  return progressAsync.whenData((all) => all.where((dp) => !dp.isPaidOff).toList());
});
