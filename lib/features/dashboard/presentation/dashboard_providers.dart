import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Dashboard data model
// ---------------------------------------------------------------------------

class CategoryExpense {
  final int categoryId;
  final String name;
  final double amount;
  final double percentage;
  final int iconCode;
  final Color color;

  CategoryExpense({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.iconCode,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Dashboard providers
// ---------------------------------------------------------------------------

/// Monto total de ingresos del mes actual
final monthlyIncomeProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db.watchMonthlyIncome(now.year, now.month);
});

/// Monto total de gastos del mes actual
final monthlyExpensesProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db.watchMonthlyExpenses(now.year, now.month);
});

/// Patrimonio neto calculado (demo: base + ingresos - gastos)
final netWorthProvider = Provider<double>((ref) {
  return 1245000.0;
});

/// Últimas transacciones para la pantalla de actividad reciente
final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentTransactions(limit: 10);
});

/// Todas las categorías
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

/// Helper para convertir hex string (#RRGGBB) a Color de Flutter
Color _hexToColor(String hex, Color fallback) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
  } catch (_) {}
  return fallback;
}

/// Lista dinámica de gastos por categoría con porcentaje, icono y color
final categoryExpensesProvider =
    StreamProvider<List<CategoryExpense>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();

  await for (final txs
      in db.watchTransactionsByMonth(now.year, now.month)) {
    final categories = await db.select(db.categories).get();
    final catMap = {for (final c in categories) c.id: c};

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
          color: _hexToColor(cat.colorHex, AppColors.tertiary),
        ));
      }
    });

    // Ordenar de mayor a menor gasto
    result.sort((a, b) => b.amount.compareTo(a.amount));
    yield result;
  }
});
