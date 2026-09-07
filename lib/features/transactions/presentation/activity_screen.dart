import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/app_providers.dart';

// ---------------------------------------------------------------------------
// Activity Screen — Historial de transacciones
// Basado en: actividad_historial_profesional/
// ---------------------------------------------------------------------------

// Filtro activo
enum _Filter { all, income, expense }

final _filterProvider = StateProvider<_Filter>((ref) => _Filter.all);
final _searchQueryProvider = StateProvider<String>((ref) => '');

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AureaAppBar(title: 'Actividad'),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _SearchBar(),
          ),
          const SizedBox(height: 12),
          // Active Goals & Debts Allocation (Item #1)
          const _ActiveGoalsAndDebtsBar(),
          const SizedBox(height: 12),
          // Filter chips
          const _FilterChips(),
          const SizedBox(height: 12),
          // Flow Chart for active filter
          const _ActivityFlowChartCard(),
          const SizedBox(height: 8),
          // Transaction list
          const Expanded(child: _TransactionList()),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
      ),
      child: TextField(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar transacciones...',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.onSurfaceVariant, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) =>
            ref.read(_searchQueryProvider.notifier).state = v.toLowerCase(),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Chip(
            label: 'Todos',
            isSelected: filter == _Filter.all,
            onTap: () =>
                ref.read(_filterProvider.notifier).state = _Filter.all,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Ingresos',
            isSelected: filter == _Filter.income,
            selectedColor: AppColors.secondary,
            onTap: () =>
                ref.read(_filterProvider.notifier).state = _Filter.income,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Gastos',
            isSelected: filter == _Filter.expense,
            selectedColor: AppColors.error,
            onTap: () =>
                ref.read(_filterProvider.notifier).state = _Filter.expense,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    this.selectedColor = AppColors.tertiary,
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
          color: isSelected
              ? selectedColor.withOpacity(0.15)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? selectedColor.withOpacity(0.4)
                : AppColors.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? selectedColor : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flow Chart Card adaptativa por filtro (_Filter)
// ---------------------------------------------------------------------------

class _ActivityFlowChartCard extends ConsumerWidget {
  const _ActivityFlowChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
        ),
        child: txsAsync.when(
          data: (txs) {
            if (txs.isEmpty) {
              return const SizedBox(
                height: 90,
                child: Center(
                  child: Text(
                    'Sin movimientos para generar gráfica',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            switch (filter) {
              case _Filter.all:
                return _buildAllFlowChart(txs);
              case _Filter.income:
                return _buildIncomeFlowChart(txs);
              case _Filter.expense:
                return _buildExpenseFlowChart(txs);
            }
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.secondary, strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildAllFlowChart(List<Transaction> txs) {
    final dateMap = <String, ({double income, double expense, DateTime date})>{};
    for (final tx in txs) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      final prev = dateMap[key] ?? (income: 0.0, expense: 0.0, date: tx.date);
      if (tx.type == 'income') {
        dateMap[key] = (income: prev.income + tx.amount, expense: prev.expense, date: tx.date);
      } else {
        dateMap[key] = (income: prev.income, expense: prev.expense + tx.amount, date: tx.date);
      }
    }

    final sortedEntries = dateMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final displayEntries = sortedEntries.length > 7 ? sortedEntries.sublist(sortedEntries.length - 7) : sortedEntries;

    double totalInc = 0;
    double totalExp = 0;
    for (final e in displayEntries) {
      totalInc += e.income;
      totalExp += e.expense;
    }
    final balance = totalInc - totalExp;

    double maxVal = 100;
    for (final e in displayEntries) {
      maxVal = max(maxVal, max(e.income, e.expense));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Flujo General de Caja',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            Row(
              children: const [
                _DotLegend(color: AppColors.tertiary, label: 'Ingresos'),
                SizedBox(width: 10),
                _DotLegend(color: AppColors.error, label: 'Gastos'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Balance: \$${balance.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: balance >= 0 ? AppColors.tertiary : AppColors.error,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(+\$${totalInc.toStringAsFixed(0)} / -\$${totalExp.toStringAsFixed(0)})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.15,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayEntries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('d MMM', 'es').format(displayEntries[idx].date),
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 9,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    final label = isIncome ? 'Ingreso' : 'Gasto';
                    return BarTooltipItem(
                      '$label: \$${rod.toY.toStringAsFixed(0)}',
                      TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? AppColors.tertiary : AppColors.error,
                      ),
                    );
                  },
                ),
              ),
              barGroups: displayEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: data.income,
                      color: AppColors.tertiary,
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: data.expense,
                      color: AppColors.error,
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeFlowChart(List<Transaction> txs) {
    final incomeTxs = txs.where((t) => t.type == 'income').toList();
    if (incomeTxs.isEmpty) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: Text(
            'Sin ingresos registrados en este periodo',
            style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final dateMap = <String, ({double amount, DateTime date})>{};
    for (final tx in incomeTxs) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      final prev = dateMap[key] ?? (amount: 0.0, date: tx.date);
      dateMap[key] = (amount: prev.amount + tx.amount, date: tx.date);
    }

    final sortedEntries = dateMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final displayEntries = sortedEntries.length > 7 ? sortedEntries.sublist(sortedEntries.length - 7) : sortedEntries;

    final totalIncome = displayEntries.fold<double>(0.0, (s, e) => s + e.amount);
    double maxVal = displayEntries.map((e) => e.amount).reduce(max);
    if (maxVal <= 0) maxVal = 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Flujo de Ingresos',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const _DotLegend(color: AppColors.secondary, label: 'Ingresos'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Total Ingresos: \$${totalIncome.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.15,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayEntries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('d MMM', 'es').format(displayEntries[idx].date),
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 9,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '+\$${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    );
                  },
                ),
              ),
              barGroups: displayEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: data.amount,
                      color: AppColors.secondary,
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseFlowChart(List<Transaction> txs) {
    final expenseTxs = txs.where((t) => t.type == 'expense').toList();
    if (expenseTxs.isEmpty) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: Text(
            'Sin gastos registrados en este periodo',
            style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final dateMap = <String, ({double amount, DateTime date})>{};
    for (final tx in expenseTxs) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      final prev = dateMap[key] ?? (amount: 0.0, date: tx.date);
      dateMap[key] = (amount: prev.amount + tx.amount, date: tx.date);
    }

    final sortedEntries = dateMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final displayEntries = sortedEntries.length > 7 ? sortedEntries.sublist(sortedEntries.length - 7) : sortedEntries;

    final totalExpense = displayEntries.fold<double>(0.0, (s, e) => s + e.amount);
    double maxVal = displayEntries.map((e) => e.amount).reduce(max);
    if (maxVal <= 0) maxVal = 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Flujo de Gastos',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const _DotLegend(color: AppColors.error, label: 'Gastos'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Total Gastos: -\$${totalExpense.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.15,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayEntries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('d MMM', 'es').format(displayEntries[idx].date),
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 9,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '-\$${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    );
                  },
                ),
              ),
              barGroups: displayEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: data.amount,
                      color: AppColors.error,
                      width: 14,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _DotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList();

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text(
          'Eliminar transacción',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
          style: TextStyle(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(recentTransactionsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final filter = ref.watch(_filterProvider);
    final query = ref.watch(_searchQueryProvider);

    return txsAsync.when(
      data: (txs) {
        final catMap = {
          for (final c in catsAsync.value ?? <Category>[]) c.id: c
        };

        // Apply filter
        var filtered = txs.where((t) {
          if (filter == _Filter.income && t.type != 'income') return false;
          if (filter == _Filter.expense && t.type != 'expense') return false;
          if (query.isNotEmpty) {
            final noteLower = t.note.toLowerCase();
            final catName =
                catMap[t.categoryId]?.name.toLowerCase() ?? '';
            return noteLower.contains(query) || catName.contains(query);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Sin transacciones',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Group by date
        final grouped = <String, List<Transaction>>{};
        for (final tx in filtered) {
          final key = DateFormat('EEEE, d MMMM', 'es').format(tx.date);
          grouped.putIfAbsent(key, () => []).add(tx);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: grouped.length,
          itemBuilder: (context, i) {
            final date = grouped.keys.elementAt(i);
            final items = grouped.values.elementAt(i);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.onSurface.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tx = entry.value;
                        return Column(
                          children: [
                            Dismissible(
                              key: ValueKey('tx-${tx.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20),
                                color: AppColors.error.withOpacity(0.15),
                                child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error),
                              ),
                              confirmDismiss: (_) =>
                                  _confirmDelete(context),
                              onDismissed: (_) async {
                                final db = ref.read(databaseProvider);
                                await db.deleteTransaction(tx.id);
                              },
                              child: _ActivityRow(
                                  transaction: tx,
                                  category: catMap[tx.categoryId],
                                  onDelete: () async {
                                    final confirmed = await _confirmDelete(context);
                                    if (confirmed) {
                                      final db = ref.read(databaseProvider);
                                      await db.deleteTransaction(tx.id);
                                    }
                                  }),
                            ),
                            if (idx < items.length - 1)
                              Divider(
                                height: 1,
                                color: AppColors.outlineVariant
                                    .withOpacity(0.15),
                                indent: 68,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.secondary, strokeWidth: 2),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback onDelete;

  const _ActivityRow({
    required this.transaction,
    this.category,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final iconColor = isIncome
        ? AppColors.tertiary
        : AppColors.onSecondaryContainer;
    final bgColor = isIncome
        ? AppColors.tertiaryContainer.withOpacity(0.2)
        : AppColors.secondaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: Icon(
              IconData(
                // ignore: non_const_argument_for_const_parameter
                category?.iconCode ?? 0xe574,
                fontFamily: 'MaterialIcons',
              ),
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isNotEmpty
                      ? transaction.note
                      : (category?.name ?? 'Transacción'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category?.name ?? '',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                amount: transaction.amount,
                isIncome: isIncome,
                fontSize: 14,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('HH:mm').format(transaction.date),
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Eliminar transacción',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bar de Metas y Deudas Activas para aportes rápidos desde Ingresos (Fix #1)
// ---------------------------------------------------------------------------

class _ActiveGoalsAndDebtsBar extends ConsumerWidget {
  const _ActiveGoalsAndDebtsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProgressProvider);
    final debtsAsync = ref.watch(activeDebtsProgressProvider);

    final goals = goalsAsync.value ?? <GoalProgress>[];
    final debts = debtsAsync.value ?? <DebtProgress>[];

    if (goals.isEmpty && debts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: AppColors.tertiary),
              SizedBox(width: 6),
              Text(
                'Aportes manuales desde Ingresos',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Metas activas
                ...goals.map((gp) => _GoalContributionChip(gp: gp)),
                // Deudas activas
                ...debts.map((dp) => _DebtPaymentChip(dp: dp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalContributionChip extends ConsumerWidget {
  final GoalProgress gp;

  const _GoalContributionChip({required this.gp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = gp.goal;
    final icon = goal.goalType == 'vacation'
        ? Icons.flight_takeoff_outlined
        : goal.goalType == 'emergency'
            ? Icons.security_outlined
            : Icons.savings_outlined;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: AppColors.tertiary),
        label: Text(
          '${goal.name} (Aportar)',
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.tertiaryContainer.withOpacity(0.2),
        side: BorderSide(color: AppColors.tertiary.withOpacity(0.4)),
        onPressed: () => _showContributeGoalSheet(context, ref, gp),
      ),
    );
  }
}

class _DebtPaymentChip extends ConsumerWidget {
  final DebtProgress dp;

  const _DebtPaymentChip({required this.dp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debt = dp.debt;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          // ignore: non_const_argument_for_const_parameter
          IconData(debt.iconCode, fontFamily: 'MaterialIcons'),
          size: 16,
          color: AppColors.error,
        ),
        label: Text(
          '${debt.name} (Pagar)',
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.errorContainer.withOpacity(0.2),
        side: BorderSide(color: AppColors.error.withOpacity(0.4)),
        onPressed: () => _showPayDebtSheet(context, ref, dp),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheets & Notificaciones de Meta/Deuda completada
// ---------------------------------------------------------------------------

void _showContributeGoalSheet(
    BuildContext context, WidgetRef ref, GoalProgress gp) {
  final controller = TextEditingController();
  final goal = gp.goal;
  final remaining = (goal.targetAmount - gp.currentContributed).clamp(0.0, double.infinity);

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aportar a "${goal.name}"',
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Faltan \$${remaining.toStringAsFixed(2)} para completar el objetivo de \$${goal.targetAmount.toStringAsFixed(2)}.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monto del aporte (\$)',
              hintText: 'Ej. 50.00',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount <= 0) return;

                final db = ref.read(databaseProvider);
                // Insert contribution
                await db.insertGoalContribution(GoalContributionsCompanion.insert(
                  goalId: goal.id,
                  amount: amount,
                  date: DateTime.now(),
                ));

                // Insert corresponding expense transaction to reflect cash outflow
                final cats = await db.getAllCategories();
                final cat = cats.firstWhere((c) => c.name == 'Otros', orElse: () => cats.first);
                await db.insertTransaction(TransactionsCompanion.insert(
                  amount: amount,
                  categoryId: cat.id,
                  type: const Value('expense'),
                  date: DateTime.now(),
                  note: Value('Aporte a meta: ${goal.name}'),
                ));

                final newTotal = gp.currentContributed + amount;
                if (ctx.mounted) Navigator.pop(ctx);

                // Celebración si se completó
                if (newTotal >= goal.targetAmount && context.mounted) {
                  _showCelebrationAlert(
                    context,
                    title: '🎉 ¡Meta Completada!',
                    message: '¡Felicitaciones! Has alcanzado tu objetivo de ahorro para "${goal.name}".',
                    color: AppColors.tertiary,
                  );
                }
              },
              child: const Text('Confirmar Aporte'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showPayDebtSheet(
    BuildContext context, WidgetRef ref, DebtProgress dp) {
  final controller = TextEditingController();
  final debt = dp.debt;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagar Deuda "${debt.name}"',
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Saldo pendiente actual: \$${dp.effectiveRemaining.toStringAsFixed(2)}.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monto del pago (\$)',
              hintText: 'Ej. 100.00',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount <= 0) return;

                final db = ref.read(databaseProvider);
                // Insert debt payment
                await db.insertDebtPayment(DebtPaymentsCompanion.insert(
                  debtId: debt.id,
                  amount: amount,
                  date: DateTime.now(),
                ));

                // Insert corresponding expense transaction to reflect cash outflow
                final cats = await db.getAllCategories();
                final cat = cats.firstWhere((c) => c.name == 'Otros', orElse: () => cats.first);
                await db.insertTransaction(TransactionsCompanion.insert(
                  amount: amount,
                  categoryId: cat.id,
                  type: const Value('expense'),
                  date: DateTime.now(),
                  note: Value('Pago de deuda: ${debt.name}'),
                ));

                final newRemaining = dp.effectiveRemaining - amount;
                if (ctx.mounted) Navigator.pop(ctx);

                // Celebración si se liquidó por completo
                if (newRemaining <= 0 && context.mounted) {
                  _showCelebrationAlert(
                    context,
                    title: '✅ ¡Deuda Liquidada!',
                    message: '¡Excelente noticia! Has pagado por completo la deuda "${debt.name}".',
                    color: AppColors.secondary,
                  );
                }
              },
              child: const Text('Registrar Pago'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showCelebrationAlert(
  BuildContext context, {
  required String title,
  required String message,
  required Color color,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.onSurface,
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
            ),
            child: const Text('¡Aceptar!'),
          ),
        ),
      ],
    ),
  );
}
