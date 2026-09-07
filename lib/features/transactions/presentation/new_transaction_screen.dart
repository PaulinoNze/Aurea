import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/app_providers.dart';

// ---------------------------------------------------------------------------
// New Transaction Screen — Numpad + Categorías + Nota
// ---------------------------------------------------------------------------

// State
final _txTypeProvider = StateProvider<String>((ref) => 'expense'); // 'expense' | 'income'
final _selectedCategoryIndexProvider = StateProvider<int>((ref) => 0);
final _amountStringProvider = StateProvider<String>((ref) => '0');
final _noteProvider = StateProvider<String>((ref) => '');

class NewTransactionScreen extends ConsumerStatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  ConsumerState<NewTransactionScreen> createState() =>
      _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    // Reset state on close
    super.dispose();
  }

  void _onNumpadPress(String value) {
    final current = ref.read(_amountStringProvider);
    String next;
    if (value == 'backspace') {
      if (current.length > 1) {
        next = current.substring(0, current.length - 1);
      } else {
        next = '0';
      }
    } else if (value == '.') {
      if (!current.contains('.')) {
        next = '$current.';
      } else {
        return;
      }
    } else {
      if (current == '0') {
        next = value;
      } else if (current.length < 10) {
        next = '$current$value';
      } else {
        return;
      }
    }
    ref.read(_amountStringProvider.notifier).state = next;
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    final amountStr = ref.read(_amountStringProvider);
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final db = ref.read(databaseProvider);
    final cats = await db.getAllCategories();
    final selectedIdx = ref.read(_selectedCategoryIndexProvider);
    final type = ref.read(_txTypeProvider);
    final note = ref.read(_noteProvider);

    final displayCategories = type == 'income'
        ? cats.where((c) => c.name == 'Nómina' || c.name == 'Otros').toList()
        : cats.where((c) => c.name != 'Nómina').toList();

    final safeIdx = selectedIdx.clamp(0, displayCategories.isNotEmpty ? displayCategories.length - 1 : 0);
    final cat = displayCategories.isNotEmpty ? displayCategories[safeIdx] : cats.first;

    await db.insertTransaction(
      TransactionsCompanion.insert(
        amount: amount,
        categoryId: cat.id,
        type: Value(type),
        date: DateTime.now(),
        note: Value(note),
      ),
    );

    // Reset
    ref.read(_amountStringProvider.notifier).state = '0';
    ref.read(_selectedCategoryIndexProvider.notifier).state = 0;
    ref.read(_noteProvider.notifier).state = '';
    ref.read(_txTypeProvider.notifier).state = 'expense';

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Toggle Gasto/Ingreso
                    _TypeToggle(),
                    const SizedBox(height: 8),
                    // Amount display
                    _AmountDisplay(),
                    const SizedBox(height: 16),
                    // Categories
                    _CategorySelector(),
                    const SizedBox(height: 16),
                    // Date + Note
                    _DetailInputs(noteController: _noteController),
                    const SizedBox(height: 12),
                    // OCR Button
                    _OcrButton(),
                  ],
                ),
              ),
            ),
            // Numpad
            _Numpad(onPress: _onNumpadPress),
            // Save button
            _SaveButton(onSave: _save, isSaving: _isSaving),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top Bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Nueva Transacción',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 48), // balancer
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type Toggle (Gasto / Ingreso)
// ---------------------------------------------------------------------------

class _TypeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(_txTypeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(child: _ToggleButton(
              label: 'Gasto',
              isSelected: type == 'expense',
              onTap: () {
                ref.read(_txTypeProvider.notifier).state = 'expense';
                ref.read(_selectedCategoryIndexProvider.notifier).state = 0;
              },
            )),
            Expanded(child: _ToggleButton(
              label: 'Ingreso',
              isSelected: type == 'income',
              onTap: () {
                ref.read(_txTypeProvider.notifier).state = 'income';
                ref.read(_selectedCategoryIndexProvider.notifier).state = 0;
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
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
// Amount Display
// ---------------------------------------------------------------------------

class _AmountDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(_amountStringProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          const Text(
            '\$',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            child: Text(
              amount,
              key: ValueKey(amount),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 52,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category Selector
// ---------------------------------------------------------------------------

class _CategorySelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = ref.watch(_selectedCategoryIndexProvider);
    final type = ref.watch(_txTypeProvider);
    final catsAsync = ref.watch(categoriesProvider);

    return catsAsync.when(
      data: (cats) {
        final displayCategories = type == 'income'
            ? cats.where((c) => c.name == 'Nómina' || c.name == 'Otros').toList()
            : cats.where((c) => c.name != 'Nómina').toList();

        if (displayCategories.isEmpty) return const SizedBox(height: 88);

        return SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemCount: displayCategories.length,
            itemBuilder: (context, i) {
              final cat = displayCategories[i];
              final isActive = selectedIdx == i;
              return GestureDetector(
                onTap: () {
                  ref.read(_selectedCategoryIndexProvider.notifier).state = i;
                  HapticFeedback.selectionClick();
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.secondaryContainer
                            : AppColors.surfaceContainerHigh,
                        border: isActive
                            ? Border.all(
                                color: AppColors.secondary, width: 1.5)
                            : Border.all(
                                color: AppColors.outlineVariant.withOpacity(0.2)),
                      ),
                      child: Icon(
                        // ignore: non_const_argument_for_const_parameter
                        IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                        color: isActive
                            ? AppColors.onSecondaryContainer
                            : AppColors.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 88),
      error: (_, _) => const SizedBox(height: 88),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Inputs (Date + Note)
// ---------------------------------------------------------------------------

class _DetailInputs extends ConsumerWidget {
  final TextEditingController noteController;

  const _DetailInputs({required this.noteController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Date chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.onSurfaceVariant),
                SizedBox(width: 6),
                Text(
                  'Hoy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Note input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.edit_note,
                        size: 18, color: AppColors.onSurfaceVariant),
                  ),
                  Expanded(
                    child: TextField(
                      controller: noteController,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Añadir nota...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                      ),
                      onChanged: (v) =>
                          ref.read(_noteProvider.notifier).state = v,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OCR Scanner Button
// ---------------------------------------------------------------------------

class _OcrButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scanner de tickets próximamente'),
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined,
                  color: AppColors.tertiary, size: 22),
              SizedBox(width: 10),
              Text(
                'Escanear Ticket',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Numpad
// ---------------------------------------------------------------------------

class _Numpad extends StatelessWidget {
  final void Function(String) onPress;

  const _Numpad({required this.onPress});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'backspace'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: keys
            .map((row) => Row(
                  children: row.map((key) {
                    return Expanded(
                      child: _NumpadKey(
                        value: key,
                        onPress: () => onPress(key),
                      ),
                    );
                  }).toList(),
                ))
            .toList(),
      ),
    );
  }
}

class _NumpadKey extends StatefulWidget {
  final String value;
  final VoidCallback onPress;

  const _NumpadKey({required this.value, required this.onPress});

  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPress();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceVariant
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.value == 'backspace'
                ? const Icon(Icons.backspace_outlined,
                    color: AppColors.onSurfaceVariant, size: 24)
                : Text(
                    widget.value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save Button
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  final bool isSaving;

  const _SaveButton({required this.onSave, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onSecondary,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 20),
          label: Text(isSaving ? 'Guardando...' : 'Guardar Localmente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
