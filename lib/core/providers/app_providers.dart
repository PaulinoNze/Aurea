import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

// ---------------------------------------------------------------------------
// Modelo de progreso de meta (calculado en memoria, no en Drift)
// ---------------------------------------------------------------------------

class GoalProgress {
  final SavingsGoal goal;
  final double netSavings;            // ahorro neto total (ingresos - gastos)
  final double progress;             // 0.0–1.0
  final double? monthlySavingsNeeded; // null si no hay deadline
  final int? daysRemaining;           // null si no hay deadline

  const GoalProgress({
    required this.goal,
    required this.netSavings,
    required this.progress,
    this.monthlySavingsNeeded,
    this.daysRemaining,
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

/// Todas las deudas (ordenadas por APR desc para método avalancha)
final debtsProvider = StreamProvider<List<Debt>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDebts();
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
// Provider derivado — Progreso de metas (Opción B: ahorro neto)
// ---------------------------------------------------------------------------

final goalsProgressProvider =
    StreamProvider<List<GoalProgress>>((ref) async* {
  final db = ref.watch(databaseProvider);
  await for (final goals in db.watchAllGoals()) {
    final income = await db.watchTotalIncome().first;
    final expenses = await db.watchTotalExpenses().first;
    final netSavings = (income - expenses).clamp(0.0, double.infinity);
    final now = DateTime.now();

    yield goals.map((goal) {
      final progress = goal.targetAmount > 0
          ? (netSavings / goal.targetAmount).clamp(0.0, 1.0)
          : 0.0;

      double? monthlySavingsNeeded;
      int? daysRemaining;

      if (goal.deadline != null && goal.deadline!.isAfter(now)) {
        daysRemaining = goal.deadline!.difference(now).inDays;
        final monthsRemaining = daysRemaining / 30.0;
        final remaining =
            (goal.targetAmount - netSavings).clamp(0.0, double.infinity);
        monthlySavingsNeeded =
            monthsRemaining > 0 ? remaining / monthsRemaining : remaining;
      }

      return GoalProgress(
        goal: goal,
        netSavings: netSavings,
        progress: progress,
        monthlySavingsNeeded: monthlySavingsNeeded,
        daysRemaining: daysRemaining,
      );
    }).toList();
  }
});
