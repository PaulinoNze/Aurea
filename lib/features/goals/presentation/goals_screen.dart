import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

// ---------------------------------------------------------------------------
// Goals & Debts Screen — Metas y Deudas
// Basado en: metas_y_deudas_espa_ol/code.html
// ---------------------------------------------------------------------------

final _goalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllGoals();
});

final _debtsProvider = StreamProvider<List<Debt>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDebts();
});

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
            // Goals Section
            FadeSlideIn(
              delay: const Duration(milliseconds: 50),
              child: const _GoalsSection(),
            ),
            const SizedBox(height: 32),

            // Debts Section
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
    final goalsAsync = ref.watch(_goalsProvider);

    return Column(
      children: [
        SectionHeader(
          title: 'Metas de Ahorro',
          actionLabel: 'Añadir Meta',
          onAction: () => _showAddGoalSheet(context, ref),
        ),
        const SizedBox(height: 16),
        goalsAsync.when(
          data: (goals) => _GoalsGrid(goals: goals),
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
  final List<SavingsGoal> goals;

  const _GoalsGrid({required this.goals});

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
        childAspectRatio: 1.35,
      ),
      itemCount: goals.length + 1, // +1 for "add" card
      itemBuilder: (context, i) {
        if (i == goals.length) {
          return _AddGoalCard(onTap: () {});
        }
        return _GoalCard(goal: goals[i]);
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalCard({required this.goal});

  static const _colors = [
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[goal.colorIndex % _colors.length];
    final progress =
        (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final pctInt = (progress * 100).toInt();

    // Icon based on type
    final icon = goal.goalType == 'vacation'
        ? Icons.flight_takeoff_outlined
        : goal.goalType == 'emergency'
            ? Icons.security_outlined
            : Icons.savings_outlined;

    // Deadline string
    String? deadlineStr;
    if (goal.deadline != null) {
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      deadlineStr =
          '${months[goal.deadline!.month - 1]} ${goal.deadline!.year}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
                            fontSize: 16,
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
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProgressRing(
                    progress: progress,
                    color: color,
                    size: 56,
                    label: '$pctInt%',
                  ),
                ],
              ),
              const Spacer(),
              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${goal.currentAmount.toInt()}',
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
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressBar(progress: progress, color: color, height: 4),
              if (deadlineStr != null) ...[
                const SizedBox(height: 12),
                Divider(
                    height: 1, color: AppColors.onSurface.withOpacity(0.08)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Finalización proyectada: $deadlineStr',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
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
      onTap: onTap,
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
// Debts Section (Avalanche Method)
// ---------------------------------------------------------------------------

class _DebtsSection extends ConsumerWidget {
  const _DebtsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(_debtsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reducción de Deuda ',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Avalancha Activa',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Enfocado en la tasa de interés más alta primero.',
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
              return const Center(
                child: Text('Sin deudas registradas',
                    style: TextStyle(color: AppColors.onSurfaceVariant)),
              );
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
                  // Debt list
                  ...debts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final debt = entry.value;
                    final isTarget = i == 0; // highest APR first
                    return Column(
                      children: [
                        _DebtRow(debt: debt, isTarget: isTarget),
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

class _DebtRow extends StatelessWidget {
  final Debt debt;
  final bool isTarget;

  const _DebtRow({required this.debt, required this.isTarget});

  @override
  Widget build(BuildContext context) {
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
                height: 56,
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
                color: isTarget
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
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
// Add Goal Bottom Sheet
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
  final int _colorIndex = 0;
  final String _type = 'savings';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la meta',
              labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetController,
            decoration: const InputDecoration(
              labelText: 'Monto objetivo (\$)',
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
                final name = _nameController.text.trim();
                final target = double.tryParse(_targetController.text) ?? 0;
                if (name.isEmpty || target <= 0) return;

                final db = ref.read(databaseProvider);
                await db.insertGoal(SavingsGoalsCompanion.insert(
                  name: name,
                  targetAmount: target,
                  goalType: Value(_type),
                  colorIndex: Value(_colorIndex),
                ));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar Meta'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
