import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';

// ---------------------------------------------------------------------------
// Dashboard Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AureaAppBar(title: 'Dashboard'),
      body: RefreshIndicator(
        color: AppColors.secondary,
        backgroundColor: AppColors.surfaceContainerHigh,
        onRefresh: () async =>
            await Future.delayed(const Duration(milliseconds: 600)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Section
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: const _NetWorthSection(),
              ),
              const SizedBox(height: 24),

              // Horizontal scrollable cards
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: const _HorizontalCards(),
              ),
              const SizedBox(height: 24),

              // Main chart + recent activity
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: const _ChartsAndActivity(),
              ),
              // bottom padding for nav bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Net Worth Section — conectado a netWorthProvider reactivo
// ---------------------------------------------------------------------------

class _NetWorthSection extends ConsumerWidget {
  const _NetWorthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(netWorthProvider);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Patrimonio Neto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          netWorthAsync.when(
            data: (netWorth) => Text(
              fmt.format(netWorth),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 40,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.8,
                color: netWorth >= 0 ? AppColors.tertiary : AppColors.error,
              ),
            ),
            loading: () => const Text(
              '--',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            error: (_, __) => const Text(
              '\$0.00',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal Scrollable Cards
// ---------------------------------------------------------------------------

class _HorizontalCards extends ConsumerWidget {
  const _HorizontalCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final budgetLimit = ref.watch(totalBudgetLimitProvider);

    final incomeVal = income.value ?? 0.0;
    final expensesVal = expenses.value ?? 0.0;
    final budgetVal = budgetLimit.value ?? 0.0;
    final budgetRemaining = (budgetVal - expensesVal).clamp(0.0, double.infinity);
    final budgetProgress = budgetVal > 0 ? (expensesVal / budgetVal).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          // Card 1 — Ingresos vs Gastos
          _SummaryCard(
            title: 'Ingresos vs Gastos',
            backgroundIcon: Icons.swap_vert,
            content: Column(
              children: [
                _IncomeExpenseRow(
                  label: 'Ingresos',
                  amount: incomeVal,
                  isIncome: true,
                  fraction: incomeVal > 0 ? 1.0 : 0.0,
                ),
                const SizedBox(height: 12),
                _IncomeExpenseRow(
                  label: 'Gastos',
                  amount: expensesVal,
                  isIncome: false,
                  fraction: incomeVal > 0
                      ? (expensesVal / incomeVal).clamp(0.0, 1.0)
                      : 0.0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card 2 — Presupuesto Restante (datos reales)
          _SummaryCard(
            title: 'Presupuesto Restante',
            backgroundIcon: Icons.account_balance_outlined,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes Actual',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                budgetVal == 0
                    ? const Text(
                        'Sin presupuesto',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${budgetRemaining.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ \$${budgetVal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                if (budgetVal > 0) ...[
                  const SizedBox(height: 10),
                  LinearProgressBar(
                    progress: budgetProgress,
                    color: budgetProgress >= 0.9
                        ? AppColors.error
                        : AppColors.tertiary,
                    height: 6,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(budgetProgress * 100).toInt()}% consumido',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: budgetProgress >= 0.9
                            ? AppColors.error
                            : AppColors.tertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData backgroundIcon;
  final Widget content;

  const _SummaryCard({
    required this.title,
    required this.backgroundIcon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Background icon watermark
          Positioned(
            top: -8,
            right: -8,
            child: Icon(
              backgroundIcon,
              size: 72,
              color: AppColors.onSurface.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  final double fraction;

  const _IncomeExpenseRow({
    required this.label,
    required this.amount,
    required this.isIncome,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.secondary : AppColors.error;
    final prefix = isIncome ? '+' : '-';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              '$prefix\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressBar(
          progress: fraction.clamp(0.0, 1.0),
          color: color,
          height: 6,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Charts & Recent Activity
// ---------------------------------------------------------------------------

class _ChartsAndActivity extends ConsumerWidget {
  const _ChartsAndActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 800;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 2, child: _DonutChartCard()),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _RecentActivityCard()),
        ],
      );
    }

    return const Column(
      children: [
        _DonutChartCard(),
        SizedBox(height: 16),
        _RecentActivityCard(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Donut Chart Card — sin datos fallback
// ---------------------------------------------------------------------------

class _DonutChartCard extends ConsumerWidget {
  const _DonutChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(categoryExpensesProvider);
    final totalExpensesAsync = ref.watch(monthlyExpensesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gastos por Categoría',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz,
                    color: AppColors.onSurfaceVariant),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          expensesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EmptyChartState(
                  message: 'Sin gastos este mes',
                  icon: Icons.pie_chart_outline,
                );
              }
              final total = totalExpensesAsync.value ??
                  items.fold<double>(0.0, (s, i) => s + i.amount);

              return Column(
                children: [
                  // Clean Center Donut Graphic
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 58,
                            sections: items
                                .map((s) => PieChartSectionData(
                                      value: s.percentage * 100,
                                      color: s.color,
                                      radius: 26,
                                      showTitle: false,
                                    ))
                                .toList(),
                          ),
                        ),
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'TOTAL GASTOS',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Detailed Category breakdown list
                  Column(
                    children: items.map((item) {
                      final pctInt = (item.percentage * 100).toInt();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconData(item.iconCode,
                                    fontFamily: 'MaterialIcons'),
                                color: item.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontFamily: 'IBM Plex Sans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '\$${item.amount.toStringAsFixed(0)} ($pctInt%)',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressBar(
                                    progress: item.percentage,
                                    color: item.color,
                                    height: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(
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
}

class _EmptyChartState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyChartState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 48,
                color: AppColors.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity Card
// ---------------------------------------------------------------------------

class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(recentTransactionsProvider);
    final catsAsync = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver todo',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          txsAsync.when(
            data: (txs) {
              final catMap = {
                for (final c in catsAsync.value ?? <Category>[]) c.id: c
              };
              if (txs.isEmpty) {
                return const _EmptyChartState(
                  message: 'Sin transacciones aún',
                  icon: Icons.receipt_long_outlined,
                );
              }
              return Column(
                children: txs
                    .take(5)
                    .map((tx) => _TransactionRow(
                          transaction: tx,
                          category: catMap[tx.categoryId],
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final Category? category;

  const _TransactionRow({required this.transaction, this.category});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final iconColor =
        isIncome ? AppColors.tertiary : AppColors.onSecondaryContainer;
    final bgColor = isIncome
        ? AppColors.tertiaryContainer.withOpacity(0.2)
        : AppColors.secondaryContainer;

    // Format date
    final now = DateTime.now();
    final diff = now.difference(transaction.date).inDays;
    final dateStr = diff == 0
        ? 'Hoy, ${DateFormat.Hm().format(transaction.date)}'
        : diff == 1
            ? 'Ayer, ${DateFormat.Hm().format(transaction.date)}'
            : DateFormat('dd MMM, HH:mm', 'es').format(transaction.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: Icon(
              IconData(
                category?.iconCode ?? 0xe574,
                fontFamily: 'MaterialIcons',
              ),
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AmountText(
            amount: transaction.amount,
            isIncome: isIncome,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}
