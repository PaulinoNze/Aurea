// ROUTER.md — Navegación Aurea (go_router)
<!--
  Documenta la navegación de la app. Lee antes de agregar rutas nuevas.
-->

## Estructura de Rutas

```
/ (ShellRoute — MainShell con BottomNav/NavigationRail)
├── /            → DashboardScreen
├── /activity    → ActivityScreen
├── /budget      → BudgetScreen
└── /goals       → GoalsScreen

/new-transaction → NewTransactionScreen (modal full-screen, slide-up)
```

## ShellRoute (MainShell)
Las 4 pantallas principales comparten el shell `MainShell` que provee:
- **Móvil**: `NavigationBar` en la parte inferior con FAB elevado para nueva transacción
- **Tablet/Desktop** (>= 600px): `NavigationRail` lateral izquierdo

## Transiciones
- Entre tabs del shell: `NoTransitionPage` (sin animación, como tabs nativas)
- `NewTransactionScreen`: `SlideTransition` desde abajo (modal sheet feel)

## Cómo navegar
```dart
// Ir a una ruta del shell
context.go(AppRoutes.dashboard);
context.go(AppRoutes.activity);

// Abrir nueva transacción (desde cualquier pantalla)
context.push(AppRoutes.newTransaction);

// Volver atrás
context.pop();
```

## Agregar una nueva ruta
1. Agregar la constante en `AppRoutes`
2. Si es parte del shell (tiene nav): agregar en `ShellRoute.routes`
3. Si es modal o pantalla independiente: agregar fuera del ShellRoute
4. Actualizar este documento

## Archivos Relacionados
- `app_router.dart` — GoRouter instance
- `lib/core/widgets/main_shell.dart` — Shell con NavigationBar/Rail
