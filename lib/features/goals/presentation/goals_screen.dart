import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/app_providers.dart';

// ---------------------------------------------------------------------------
// Goals & Debts Screen — Metas y Deudas
// ---------------------------------------------------------------------------

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AureaAppBar(title: 'Metas y Deudas'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              delay: const Duration(milliseconds: 50),
              child: const _GoalsSection(),
            ),
            const SizedBox(height: 32),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: const _DebtsSection(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goals Section
// ---------------------------------------------------------------------------

class _GoalsSection extends ConsumerWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalsProgressProvider);

    return Column(
      children: [
        SectionHeader(
          title: 'Metas de Ahorro',
          actionLabel: 'Añadir Meta',
          onAction: () => _showAddGoalSheet(context, ref),
        ),
        const SizedBox(height: 16),
        progressAsync.when(
          data: (progressList) =>
              _GoalsGrid(progressList: progressList, ref: ref),
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
    );
  }
}

class _GoalsGrid extends StatelessWidget {
  final List<GoalProgress> progressList;
  final WidgetRef ref;

  const _GoalsGrid({required this.progressList, required this.ref});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 800 ? 3 : (width >= 500 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: progressList.length + 1, // +1 for "add" card
      itemBuilder: (context, i) {
        if (i == progressList.length) {
          // FIX #8a: onTap conectado al sheet de creación
          return _AddGoalCard(
              onTap: () => _showAddGoalSheet(context, ref));
        }
        return _GoalCard(
          gp: progressList[i],
          onDelete: () async {
            final confirmed = await _confirmDelete(
                context, '¿Eliminar la meta "${progressList[i].goal.name}"?');
            if (confirmed) {
              final db = ref.read(databaseProvider);
              await db.deleteGoal(progressList[i].goal.id);
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Goal Card con progreso real
// ---------------------------------------------------------------------------

class _GoalCard extends StatelessWidget {
  final GoalProgress gp;
  final VoidCallback onDelete;

  const _GoalCard({required this.gp, required this.onDelete});

  static const _colors = [
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final goal = gp.goal;
    final color = _colors[goal.colorIndex % _colors.length];
    final progress = gp.progress;
    final pctInt = (progress * 100).toInt();

    // Icon based on type
    final icon = goal.goalType == 'vacation'
        ? Icons.flight_takeoff_outlined
        : goal.goalType == 'emergency'
            ? Icons.security_outlined
            : Icons.savings_outlined;

    // Deadline string and days remaining
    String? deadlineStr;
    String? daysStr;
    if (goal.deadline != null) {
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      deadlineStr =
          '${months[goal.deadline!.month - 1]} ${goal.deadline!.year}';
      if (gp.daysRemaining != null) {
        daysStr = 'Faltan ${gp.daysRemaining} días';
      } else if (goal.deadline!.isBefore(DateTime.now())) {
        daysStr = 'Plazo vencido';
      }
    }

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.onSurface.withOpacity(0.06)),
        ),
        child: Stack(
          children: [
            // Glow blob
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _typeLabel(goal.goalType),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ProgressRing(
                      progress: progress,
                      color: color,
                      size: 50,
                      label: '$pctInt%',
                    ),
                  ],
                ),
                const Spacer(),
                // Ahorro neto vs objetivo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${gp.netSavings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'de \$${goal.targetAmount.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressBar(progress: progress, color: color, height: 4),

                // Ahorro mensual necesario
                if (gp.monthlySavingsNeeded != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '\$${gp.monthlySavingsNeeded!.toStringAsFixed(0)}/mes para cumplirla',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],

                // Deadline
                if (deadlineStr != null) ...[
                  const SizedBox(height: 8),
                  Divider(
                      height: 1,
                      color: AppColors.onSurface.withOpacity(0.08)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          deadlineStr,
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (daysStr != null)
                        Text(
                          daysStr,
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'vacation':
        return 'Fondo de vacaciones';
      case 'emergency':
        return 'Fondo de emergencia';
      default:
        return 'Meta de ahorro';
    }
  }
}

class _AddGoalCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddGoalCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // FIX #8a: ya no está vacío
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant.withOpacity(0.5),
              ),
              child: const Icon(Icons.add,
                  color: AppColors.onSurfaceVariant, size: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Crear Nueva Meta',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
// Debts Section (Avalanche / Snowball)
// ---------------------------------------------------------------------------

class _DebtsSection extends ConsumerWidget {
  const _DebtsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reducción de Deuda',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.tertiary),
              tooltip: 'Añadir deuda',
              onPressed: () => _showAddDebtSheet(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Método: paga primero la deuda con mayor interés.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        debtsAsync.when(
          data: (debts) {
            if (debts.isEmpty) {
              return _EmptyDebtsState(
                  onAdd: () => _showAddDebtSheet(context, ref));
            }
            final totalRemaining =
                debts.fold(0.0, (s, d) => s + d.remainingAmount);
            final totalMonthly = debts.fold(
                0.0, (s, d) => s + d.minimumPayment + d.extraPayment);

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  // Summary header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL RESTANTE',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${totalRemaining.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'PAGO MENSUAL',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${totalMonthly.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withOpacity(0.2)),
                  // Debt list with delete
                  ...debts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final debt = entry.value;
                    final isTarget = i == 0;
                    return Column(
                      children: [
                        Dismissible(
                          key: ValueKey('debt-${debt.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: AppColors.error.withOpacity(0.1),
                            child: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                          ),
                          confirmDismiss: (_) => _confirmDelete(
                              context, '¿Eliminar la deuda "${debt.name}"?'),
                          onDismissed: (_) async {
                            final db = ref.read(databaseProvider);
                            await db.deleteDebt(debt.id);
                          },
                          child: _DebtRow(debt: debt, isTarget: isTarget),
                        ),
                        if (i < debts.length - 1)
                          Divider(
                              height: 1,
                              color: AppColors.outlineVariant.withOpacity(0.2)),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.secondary, strokeWidth: 2),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _EmptyDebtsState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDebtsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.credit_card_off_outlined,
              size: 48,
              color: AppColors.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            'Sin deudas registradas',
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
            label: const Text('Registrar deuda'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debt Row con proyección de pago
// ---------------------------------------------------------------------------

class _DebtRow extends StatelessWidget {
  final Debt debt;
  final bool isTarget;

  const _DebtRow({required this.debt, required this.isTarget});

  /// Calcula los meses para pagar la deuda con la fórmula de amortización estándar.
  /// Si la tasa es 0%, divide monto / pago mensual.
  int _payoffMonths() {
    final monthlyPayment = debt.minimumPayment + debt.extraPayment;
    if (monthlyPayment <= 0) return 0;
    if (debt.interestRate <= 0) {
      return (debt.remainingAmount / monthlyPayment).ceil();
    }
    final r = debt.interestRate / 100 / 12; // tasa mensual
    final n = debt.remainingAmount;
    final p = monthlyPayment;

    if (p <= n * r) return 9999; // pago insuficiente para cubrir intereses

    // Fórmula: -ln(1 - n*r/p) / ln(1+r)
    final months = -log(1 - (n * r / p)) / log(1 + r);
    return months.ceil();
  }

  @override
  Widget build(BuildContext context) {
    final months = _payoffMonths();
    final payoffStr = months == 0
        ? 'Sin pagos definidos'
        : months >= 9999
            ? 'Pago insuficiente'
            : months >= 12
                ? 'Libre en ~${(months / 12).toStringAsFixed(1)} años'
                : 'Libre en $months meses';

    return Opacity(
      opacity: isTarget ? 1.0 : 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Target indicator
            if (isTarget)
              Container(
                width: 3,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTarget
                    ? AppColors.errorContainer.withOpacity(0.2)
                    : AppColors.surfaceVariant,
              ),
              child: Icon(
                IconData(debt.iconCode, fontFamily: 'MaterialIcons'),
                color:
                    isTarget ? AppColors.error : AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          debt.name,
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTarget) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OBJETIVO',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${debt.interestRate}% APR',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    payoffStr,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isTarget ? AppColors.error : AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${debt.remainingAmount.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  isTarget
                      ? 'Pagando \$${(debt.minimumPayment + debt.extraPayment).toInt()}/mo'
                      : 'Mín. \$${debt.minimumPayment.toInt()}/mo',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isTarget
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Goal Bottom Sheet — con date picker (Fix #2)
// ---------------------------------------------------------------------------

void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddGoalSheet(),
  );
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  int _colorIndex = 0;
  String _type = 'savings';
  DateTime? _targetDate;

  static const _typeOptions = [
    ('savings', 'Ahorro General', Icons.savings_outlined),
    ('vacation', 'Vacaciones', Icons.flight_takeoff_outlined),
    ('emergency', 'Emergencia', Icons.security_outlined),
  ];

  static const _colorOptions = [
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.error,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.secondary,
            surface: AppColors.surfaceContainerLow,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy', 'es');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva Meta de Ahorro',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Nombre
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la meta',
                labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              style: const TextStyle(color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),

            // Monto objetivo
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Monto objetivo (\$)',
                labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),

            // Tipo de meta
            const Text(
              'Tipo',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _typeOptions.map((opt) {
                final (value, label, icon) = opt;
                final isSelected = _type == value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withOpacity(0.15)
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.onSurfaceVariant),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Color
            const Text(
              'Color',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.asMap().entries.map((e) {
                final isSelected = _colorIndex == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.value,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Fecha objetivo — date picker (Fix #2)
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      _targetDate != null
                          ? 'Fecha objetivo: ${dateFmt.format(_targetDate!)}'
                          : 'Fecha objetivo (opcional)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: _targetDate != null
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final target =
                      double.tryParse(_targetController.text) ?? 0;
                  if (name.isEmpty || target <= 0) return;

                  final db = ref.read(databaseProvider);
                  await db.insertGoal(SavingsGoalsCompanion.insert(
                    name: name,
                    targetAmount: target,
                    goalType: Value(_type),
                    colorIndex: Value(_colorIndex),
                    deadline: Value(_targetDate),
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Meta'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Debt Bottom Sheet (Fix #8b)
// ---------------------------------------------------------------------------

void _showAddDebtSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddDebtSheet(),
  );
}

class _AddDebtSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<_AddDebtSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _minPaymentController = TextEditingController();
  final _extraPaymentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _minPaymentController.dispose();
    _extraPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar Deuda',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _buildField(_nameController, 'Nombre de la deuda', false),
            const SizedBox(height: 16),
            _buildField(
                _amountController, 'Monto restante (\$)', true),
            const SizedBox(height: 16),
            _buildField(
                _rateController, 'Tasa de interés (APR %)', true),
            const SizedBox(height: 16),
            _buildField(
                _minPaymentController, 'Pago mínimo mensual (\$)', true),
            const SizedBox(height: 16),
            _buildField(
                _extraPaymentController, 'Pago extra mensual (\$)', true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final amount =
                      double.tryParse(_amountController.text) ?? 0;
                  final rate =
                      double.tryParse(_rateController.text) ?? 0;
                  final minPay =
                      double.tryParse(_minPaymentController.text) ?? 0;
                  final extraPay =
                      double.tryParse(_extraPaymentController.text) ?? 0;
                  if (name.isEmpty || amount <= 0 || minPay <= 0) return;

                  final db = ref.read(databaseProvider);
                  await db.insertDebt(DebtsCompanion.insert(
                    name: name,
                    remainingAmount: amount,
                    interestRate: rate,
                    minimumPayment: minPay,
                    extraPayment: Value(extraPay),
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Registrar Deuda'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, bool isNumeric) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      ),
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: AppColors.onSurface),
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
