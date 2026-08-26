import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

// ---------------------------------------------------------------------------
// Budget Screen — Presupuestos y Análisis
// Basado en: presupuestos_an_lisis_avanzado/code.html
// ---------------------------------------------------------------------------

enum _BudgetPeriod { weekly, monthly, yearly }

final _periodProvider = StateProvider<_BudgetPeriod>((ref) => _BudgetPeriod.monthly);

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
            // Header + Period Selector
            FadeSlideIn(
              delay: const Duration(milliseconds: 50),
              child: const _BudgetHeader(),
            ),
            const SizedBox(height: 24),

            // Main grid
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
// Header
// ---------------------------------------------------------------------------

class _BudgetHeader extends ConsumerWidget {
  const _BudgetHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);

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
            color: isSelected
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget Content
// ---------------------------------------------------------------------------

class _BudgetContent extends ConsumerWidget {
  const _BudgetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
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
// Budget by Category
// ---------------------------------------------------------------------------

const _budgetData = [
  (
    name: 'Comida y Restaurantes',
    icon: Icons.restaurant,
    used: 850.0,
    total: 1000.0,
    color: AppColors.secondary,
    bgColor: AppColors.secondaryContainer,
    iconColor: AppColors.onSecondaryContainer,
  ),
  (
    name: 'Transporte',
    icon: Icons.directions_car,
    used: 160.0,
    total: 400.0,
    color: AppColors.primary,
    bgColor: AppColors.primaryContainer,
    iconColor: AppColors.primary,
  ),
  (
    name: 'Compras',
    icon: Icons.shopping_bag_outlined,
    used: 230.0,
    total: 300.0,
    color: AppColors.tertiary,
    bgColor: AppColors.tertiaryContainer,
    iconColor: AppColors.onTertiary,
  ),
  (
    name: 'Vivienda',
    icon: Icons.home_outlined,
    used: 1200.0,
    total: 1500.0,
    color: AppColors.error,
    bgColor: AppColors.errorContainer,
    iconColor: AppColors.error,
  ),
];

class _BudgetCategories extends StatelessWidget {
  const _BudgetCategories();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),
          ...List.generate(_budgetData.length, (i) {
            final d = _budgetData[i];
            final pct = (d.used / d.total).clamp(0.0, 1.0);
            final isOverBudget = d.used >= d.total * 0.9;
            return Padding(
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
                          color: d.bgColor,
                        ),
                        child: Icon(d.icon, color: d.iconColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              '${(pct * 100).toInt()}% del presupuesto usado',
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${d.used.toInt()}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '/ \$${d.total.toInt()}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressBar(
                    progress: pct,
                    color: isOverBudget ? AppColors.error : d.color,
                    height: 5,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spending Analysis (Bar Chart)
// ---------------------------------------------------------------------------

class _SpendingAnalysis extends StatelessWidget {
  const _SpendingAnalysis();

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Resumen del Mes',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                  label: 'Total Presupuestado',
                  value: '\$3,200',
                  color: AppColors.onSurface),
              const SizedBox(height: 10),
              _SummaryRow(
                  label: 'Total Gastado',
                  value: '\$2,440',
                  color: AppColors.secondary),
              const SizedBox(height: 10),
              _SummaryRow(
                  label: 'Restante',
                  value: '\$760',
                  color: AppColors.tertiary),
              const SizedBox(height: 16),
              LinearProgressBar(
                progress: 2440 / 3200,
                color: AppColors.secondary,
                height: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Weekly bar chart
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
              const Text(
                'Gastos por Semana',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    backgroundColor: Colors.transparent,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 200,
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
                            const weeks = ['S1', 'S2', 'S3', 'S4'];
                            return Text(
                              weeks[v.toInt()],
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(
                            toY: 620,
                            color: AppColors.secondary.withOpacity(0.6),
                            width: 24,
                            borderRadius: BorderRadius.circular(6))
                      ]),
                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(
                            toY: 780,
                            color: AppColors.secondary.withOpacity(0.6),
                            width: 24,
                            borderRadius: BorderRadius.circular(6))
                      ]),
                      BarChartGroupData(x: 2, barRods: [
                        BarChartRodData(
                            toY: 550,
                            color: AppColors.secondary.withOpacity(0.6),
                            width: 24,
                            borderRadius: BorderRadius.circular(6))
                      ]),
                      BarChartGroupData(x: 3, barRods: [
                        BarChartRodData(
                            toY: 490,
                            color: AppColors.tertiary,
                            width: 24,
                            borderRadius: BorderRadius.circular(6))
                      ]),
                    ],
                    maxY: 1000,
                  ),
                ),
              ),
            ],
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
