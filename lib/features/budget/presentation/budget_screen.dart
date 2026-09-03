import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/app_providers.dart';

// ---------------------------------------------------------------------------
// Budget Screen — Presupuestos y Análisis (datos reales de Drift)
// ---------------------------------------------------------------------------

enum _BudgetPeriod { weekly, monthly, yearly }

/// Mes navegable seleccionado (por defecto: mes actual)
final _selectedMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));

final _periodProvider =
    StateProvider<_BudgetPeriod>((ref) => _BudgetPeriod.monthly);

// ---------------------------------------------------------------------------
// Modelo calculado de presupuesto por categoría
// ---------------------------------------------------------------------------

class BudgetCategoryData {
  final Budget budget;
  final Category category;
  final double spent;
  final double progress; // 0.0–1.0

  const BudgetCategoryData({
    required this.budget,
    required this.category,
    required this.spent,
    required this.progress,
  });
}

// ---------------------------------------------------------------------------
// Provider de datos de presupuesto por mes y periodo
// ---------------------------------------------------------------------------

final _budgetDataProvider =
    StreamProvider<List<BudgetCategoryData>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final selectedMonth = ref.watch(_selectedMonthProvider);
  final period = ref.watch(_periodProvider);

  DateTime start;
  DateTime end;
  double multiplier = 1.0;

  switch (period) {
    case _BudgetPeriod.weekly:
      final now = DateTime.now();
      final baseDate = (now.year == selectedMonth.year && now.month == selectedMonth.month)
          ? now
          : DateTime(selectedMonth.year, selectedMonth.month, 15);
      final weekStart = baseDate.subtract(Duration(days: baseDate.weekday - 1));
      start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      end = start.add(const Duration(days: 7));
      multiplier = 0.25;
      break;
    case _BudgetPeriod.monthly:
      start = DateTime(selectedMonth.year, selectedMonth.month, 1);
      end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
      multiplier = 1.0;
      break;
    case _BudgetPeriod.yearly:
      start = DateTime(selectedMonth.year, 1, 1);
      end = DateTime(selectedMonth.year + 1, 1, 1);
      multiplier = 12.0;
      break;
  }

  await for (final txs in db.watchTransactionsByRange(start, end)) {
    final budgetList = await db.watchAllBudgets().first;
    final catList = await db.getAllCategories();
    final catMap = {for (final c in catList) c.id: c};

    final spentMap = <int, double>{};
    for (final tx in txs.where((t) => t.type == 'expense')) {
      spentMap[tx.categoryId] = (spentMap[tx.categoryId] ?? 0) + tx.amount;
    }

    final result = <BudgetCategoryData>[];
    for (final budget in budgetList) {
      final cat = catMap[budget.categoryId];
      if (cat == null) continue;
      final spent = spentMap[budget.categoryId] ?? 0.0;
      final adjustedLimit = budget.amount * multiplier;
      result.add(BudgetCategoryData(
        budget: Budget(
          id: budget.id,
          categoryId: budget.categoryId,
          amount: adjustedLimit,
          period: budget.period,
        ),
        category: cat,
        spent: spent,
        progress: adjustedLimit > 0
            ? (spent / adjustedLimit).clamp(0.0, 1.0)
            : 0.0,
      ));
    }

    result.sort((a, b) => b.spent.compareTo(a.spent));
    yield result;
  }
});

class PeriodExpensesData {
  final String chartTitle;
  final List<String> labels;
  final List<double> values;

  const PeriodExpensesData({
    required this.chartTitle,
    required this.labels,
    required this.values,
  });
}

final _periodExpensesProvider =
    StreamProvider<PeriodExpensesData>((ref) async* {
  final db = ref.watch(databaseProvider);
  final selectedMonth = ref.watch(_selectedMonthProvider);
  final period = ref.watch(_periodProvider);

  switch (period) {
    case _BudgetPeriod.weekly:
      final now = DateTime.now();
      final baseDate = (now.year == selectedMonth.year && now.month == selectedMonth.month)
          ? now
          : DateTime(selectedMonth.year, selectedMonth.month, 15);
      final weekStart = baseDate.subtract(Duration(days: baseDate.weekday - 1));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = start.add(const Duration(days: 7));

      await for (final txs in db.watchTransactionsByRange(start, end)) {
        final expenses = txs.where((t) => t.type == 'expense');
        final days = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        for (final tx in expenses) {
          final idx = (tx.date.weekday - 1).clamp(0, 6);
          days[idx] += tx.amount;
        }
        yield PeriodExpensesData(
          chartTitle: 'Gastos por Día (Esta Semana)',
          labels: const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
          values: days,
        );
      }
      break;

    case _BudgetPeriod.monthly:
      final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

      await for (final txs in db.watchTransactionsByRange(monthStart, monthEnd)) {
        final expenses = txs.where((t) => t.type == 'expense');
        final weeks = [0.0, 0.0, 0.0, 0.0];
        for (final tx in expenses) {
          final day = tx.date.day;
          final weekIdx = ((day - 1) / 7).floor().clamp(0, 3);
          weeks[weekIdx] += tx.amount;
        }
        yield PeriodExpensesData(
          chartTitle: 'Gastos por Semana (Mes)',
          labels: const ['S1', 'S2', 'S3', 'S4'],
          values: weeks,
        );
      }
      break;

    case _BudgetPeriod.yearly:
      final yearStart = DateTime(selectedMonth.year, 1, 1);
      final yearEnd = DateTime(selectedMonth.year + 1, 1, 1);

      await for (final txs in db.watchTransactionsByRange(yearStart, yearEnd)) {
        final expenses = txs.where((t) => t.type == 'expense');
        final months = List<double>.filled(12, 0.0);
        for (final tx in expenses) {
          final mIdx = (tx.date.month - 1).clamp(0, 11);
          months[mIdx] += tx.amount;
        }
        yield PeriodExpensesData(
          chartTitle: 'Gastos por Mes (Año ${selectedMonth.year})',
          labels: const [
            'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
            'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
          ],
          values: months,
        );
      }
      break;
  }
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AureaAppBar(title: 'Presupuestos'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              delay: const Duration(milliseconds: 50),
              child: const _BudgetHeader(),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: const _BudgetContent(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header con navegación de meses y selector de periodo
// ---------------------------------------------------------------------------

class _BudgetHeader extends ConsumerWidget {
  const _BudgetHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final selectedMonth = ref.watch(_selectedMonthProvider);
    final monthFmt = DateFormat('MMMM yyyy', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presupuestos y Análisis',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rastrea tus gastos y proyecta tu liquidez.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                final cur = ref.read(_selectedMonthProvider);
                ref.read(_selectedMonthProvider.notifier).state =
                    DateTime(cur.year, cur.month - 1);
              },
              icon: const Icon(Icons.chevron_left,
                  color: AppColors.onSurfaceVariant),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            ),
            Text(
              monthFmt.format(selectedMonth).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                final cur = ref.read(_selectedMonthProvider);
                ref.read(_selectedMonthProvider.notifier).state =
                    DateTime(cur.year, cur.month + 1);
              },
              icon: const Icon(Icons.chevron_right,
                  color: AppColors.onSurfaceVariant),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Period toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PeriodButton(
                  label: 'Semanal',
                  isSelected: period == _BudgetPeriod.weekly,
                  onTap: () => ref.read(_periodProvider.notifier).state =
                      _BudgetPeriod.weekly),
              _PeriodButton(
                  label: 'Mensual',
                  isSelected: period == _BudgetPeriod.monthly,
                  onTap: () => ref.read(_periodProvider.notifier).state =
                      _BudgetPeriod.monthly),
              _PeriodButton(
                  label: 'Anual',
                  isSelected: period == _BudgetPeriod.yearly,
                  onTap: () => ref.read(_periodProvider.notifier).state =
                      _BudgetPeriod.yearly),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget Content Grid
// ---------------------------------------------------------------------------

class _BudgetContent extends ConsumerWidget {
  const _BudgetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;

    if (isWide) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _BudgetCategories()),
          SizedBox(width: 16),
          Expanded(flex: 1, child: _SpendingAnalysis()),
        ],
      );
    }

    return const Column(
      children: [
        _BudgetCategories(),
        SizedBox(height: 16),
        _SpendingAnalysis(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Budget by Category — datos reales de Drift
// ---------------------------------------------------------------------------

class _BudgetCategories extends ConsumerWidget {
  const _BudgetCategories();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetDataAsync = ref.watch(_budgetDataProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Presupuestos por Categoría',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.tertiary),
                tooltip: 'Añadir presupuesto',
                onPressed: () => _showAddBudgetSheet(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          budgetDataAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _EmptyBudgetState(
                    onAdd: () => _showAddBudgetSheet(context, ref));
              }
              return Column(
                children: items.map((d) {
                  final isOverBudget = d.spent >= d.budget.amount * 0.9;
                  final color = isOverBudget
                      ? AppColors.error
                      : _categoryColor(d.category.colorHex);

                  return Dismissible(
                    key: ValueKey('budget-${d.budget.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                    ),
                    confirmDismiss: (_) => _confirmDelete(
                        context, '¿Eliminar presupuesto de ${d.category.name}?'),
                    onDismissed: (_) async {
                      final db = ref.read(databaseProvider);
                      await db.deleteBudget(d.budget.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withOpacity(0.15),
                                ),
                                child: Icon(
                                  IconData(d.category.iconCode,
                                      fontFamily: 'MaterialIcons'),
                                  color: color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.category.name,
                                      style: const TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${(d.progress * 100).toInt()}% del presupuesto usado',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: isOverBudget
                                            ? AppColors.error
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${d.spent.toInt()}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '/ \$${d.budget.amount.toInt()}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Eliminar presupuesto',
                                onPressed: () async {
                                  final confirmed = await _confirmDelete(
                                      context,
                                      '¿Eliminar presupuesto de ${d.category.name}?');
                                  if (confirmed) {
                                    final db = ref.read(databaseProvider);
                                    await db.deleteBudget(d.budget.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressBar(
                            progress: d.progress,
                            color: color,
                            height: 5,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                    color: AppColors.secondary, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return AppColors.tertiary;
  }
}

class _EmptyBudgetState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBudgetState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            'Sin presupuestos definidos',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir presupuesto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.tertiary,
              side: const BorderSide(color: AppColors.tertiary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spending Analysis — datos reales
// ---------------------------------------------------------------------------

class _SpendingAnalysis extends ConsumerWidget {
  const _SpendingAnalysis();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetDataAsync = ref.watch(_budgetDataProvider);
    final periodDataAsync = ref.watch(_periodExpensesProvider);
    final selectedMonth = ref.watch(_selectedMonthProvider);
    final monthFmt = DateFormat('MMMM', 'es');

    return Column(
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen — ${monthFmt.format(selectedMonth)}',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              budgetDataAsync.when(
                data: (items) {
                  final totalBudget = items.fold(
                      0.0, (s, d) => s + d.budget.amount);
                  final totalSpent =
                      items.fold(0.0, (s, d) => s + d.spent);
                  final remaining =
                      (totalBudget - totalSpent).clamp(0.0, double.infinity);
                  final progress = totalBudget > 0
                      ? (totalSpent / totalBudget).clamp(0.0, 1.0)
                      : 0.0;

                  if (items.isEmpty) {
                    return const Text(
                      'Añade presupuestos para ver el resumen.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _SummaryRow(
                          label: 'Total Presupuestado',
                          value: '\$${totalBudget.toInt()}',
                          color: AppColors.onSurface),
                      const SizedBox(height: 10),
                      _SummaryRow(
                          label: 'Total Gastado',
                          value: '\$${totalSpent.toInt()}',
                          color: AppColors.secondary),
                      const SizedBox(height: 10),
                      _SummaryRow(
                          label: 'Restante',
                          value: '\$${remaining.toInt()}',
                          color: AppColors.tertiary),
                      const SizedBox(height: 16),
                      LinearProgressBar(
                        progress: progress,
                        color: progress >= 0.9
                            ? AppColors.error
                            : AppColors.secondary,
                        height: 8,
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(
                    color: AppColors.secondary, strokeWidth: 2),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Period Bar Chart — datos reales dinámicos (Semanal/Mensual/Anual)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: periodDataAsync.when(
            data: (pData) {
              final values = pData.values;
              final labels = pData.labels;
              final maxY = values.fold<double>(0.0, (a, b) => a > b ? a : b);
              final chartMax = maxY > 0 ? (maxY * 1.3).ceilToDouble() : 100.0;
              final hasData = values.any((w) => w > 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pData.chartTitle,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!hasData)
                    const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Sin gastos en este periodo',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          backgroundColor: Colors.transparent,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: chartMax / 4,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: AppColors.outlineVariant.withOpacity(0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    labels[idx],
                                    style: const TextStyle(
                                      fontFamily: 'IBM Plex Sans',
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: values.asMap().entries.map((e) {
                            final isLast = e.key == values.length - 1;
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: isLast
                                      ? AppColors.tertiary
                                      : AppColors.secondary.withOpacity(0.6),
                                  width: labels.length > 8 ? 12 : 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                          maxY: chartMax,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.secondary, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmación de borrado
// ---------------------------------------------------------------------------

Future<bool> _confirmDelete(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      title: const Text(
        'Confirmar eliminación',
        style: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ---------------------------------------------------------------------------
// Add Budget Bottom Sheet
// ---------------------------------------------------------------------------

void _showAddBudgetSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _AddBudgetSheet(),
  );
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  const _AddBudgetSheet();

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  final _amountController = TextEditingController();
  Category? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + bottomPadding + 32,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'Nuevo Presupuesto',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          catsAsync.when(
            data: (cats) => DropdownButtonFormField<Category>(
              value: _selectedCategory,
              dropdownColor: AppColors.surfaceContainerLow,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              style: const TextStyle(color: AppColors.onSurface),
              items: cats
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Límite mensual (\$)',
              labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text) ?? 0;
                if (_selectedCategory == null || amount <= 0) return;

                final db = ref.read(databaseProvider);
                await db.insertBudget(BudgetsCompanion.insert(
                  categoryId: _selectedCategory!.id,
                  amount: amount,
                ));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar Presupuesto'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
}
