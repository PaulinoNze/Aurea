import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Shell adaptativo:
/// - Móvil: BottomNavigationBar con FAB elevado
/// - Tablet/Desktop (>= 600px): NavigationRail lateral
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  // Determina el índice activo según la ruta
  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.activity)) return 1;
    if (location.startsWith(AppRoutes.budget)) return 2;
    if (location.startsWith(AppRoutes.goals)) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.activity);
        break;
      case 2:
        context.go(AppRoutes.budget);
        break;
      case 3:
        context.go(AppRoutes.goals);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    if (isWide) {
      return _WideLayout(
        child: child,
        selectedIndex: _locationIndex(context),
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
      );
    }

    return _MobileLayout(
      child: child,
      selectedIndex: _locationIndex(context),
      onDestinationSelected: (i) => _onDestinationSelected(context, i),
    );
  }
}

// ---------------------------------------------------------------------------
// MOBILE LAYOUT
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _MobileLayout({
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      extendBody: true,
      bottomNavigationBar: _AureaBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDE LAYOUT (tablet / desktop)
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _WideLayout({
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _AureaNavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BOTTOM NAVIGATION BAR
// ---------------------------------------------------------------------------

class _AureaBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _AureaBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withOpacity(0.92),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.15),
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Actividad',
                    isSelected: selectedIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                  // FAB placeholder space
                  const SizedBox(width: 72),
                  _NavItem(
                    icon: Icons.pie_chart_outline,
                    activeIcon: Icons.pie_chart,
                    label: 'Presupuestos',
                    isSelected: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                  _NavItem(
                    icon: Icons.emoji_events_outlined,
                    activeIcon: Icons.emoji_events,
                    label: 'Metas',
                    isSelected: selectedIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                ],
              ),
              // FAB elevado (Nueva Transacción)
              Positioned(
                top: -24,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.newTransaction),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.onSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.tertiary : AppColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NAVIGATION RAIL (tablet / desktop)
// ---------------------------------------------------------------------------

class _AureaNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _AureaNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: AppColors.tertiary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Aurea',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Nav items
          ...[
            (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
            (Icons.receipt_long_outlined, Icons.receipt_long, 'Actividad', 1),
            (Icons.pie_chart_outline, Icons.pie_chart, 'Presupuestos', 2),
            (Icons.emoji_events_outlined, Icons.emoji_events, 'Metas', 3),
          ].map((item) {
            final (outlinedIcon, filledIcon, label, index) = item;
            final isSelected = selectedIndex == index;
            return _RailItem(
              icon: outlinedIcon,
              activeIcon: filledIcon,
              label: label,
              isSelected: isSelected,
              onTap: () => onDestinationSelected(index),
            );
          }),
          const Spacer(),
          // FAB en rail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: InkWell(
              onTap: () => context.push(AppRoutes.newTransaction),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.onSecondary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Nueva Transacción',
                      style: TextStyle(
                        color: AppColors.onSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceVariant.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.tertiary : AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.tertiary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
