import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/database/app_database.dart';
import '../../dashboard/presentation/dashboard_providers.dart';

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
          // Filter chips
          const _FilterChips(),
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

class _TransactionList extends ConsumerWidget {
  const _TransactionList();

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
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final tx = entry.value;
                      return Column(
                        children: [
                          _ActivityRow(
                              transaction: tx,
                              category: catMap[tx.categoryId]),
                          if (idx < items.length - 1)
                            Divider(
                              height: 1,
                              color:
                                  AppColors.outlineVariant.withOpacity(0.15),
                              indent: 68,
                            ),
                        ],
                      );
                    }).toList(),
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

  const _ActivityRow({required this.transaction, this.category});

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
        ],
      ),
    );
  }
}
