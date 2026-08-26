# GOALS.md — Pantalla Metas y Deudas

## Componentes Visuales

### GoalsScreen
- **_GoalsSection**: Grid de GoalCards + AddGoalCard
- **_DebtsSection**: Header con badge "Avalancha Activa" + lista de deudas

### GoalCard
Renderiza una meta de ahorro con:
- **ProgressRing** (CustomPainter animado) — progreso circular con color de la meta
- **LinearProgressBar** — barra de progreso lineal debajo del monto
- **Glow blob** — círculo decorativo semitransparente en esquina superior derecha
- **Deadline row** — ícono + texto "Finalización proyectada: MMM YYYY"

### Colores de Metas (por `colorIndex`)
| Index | Color | Uso |
|---|---|---|
| 0 | `AppColors.secondary` | Fondo de emergencia (verde) |
| 1 | `AppColors.tertiary` | Viaje/Vacaciones (dorado) |
| 2 | `AppColors.error` | Deudas/Urgente (terracota) |

### AddGoalCard
Tarjeta dashed con botón "+" que abre `_AddGoalSheet` (BottomSheet)

### DebtRow
- **isTarget = true** (primera deuda = mayor APR): indicador rojo de 3px a la izquierda, badge "OBJETIVO"
- **isTarget = false**: Opacity 0.7 para indicar menor prioridad
- Pago mostrado: para target = `minimumPayment + extraPayment`; para otros = solo `minimumPayment`

## Providers
| Provider | Tipo | Descripción |
|---|---|---|
| `_goalsProvider` | `StreamProvider<List<SavingsGoal>>` | Stream de metas ordenadas por id |
| `_debtsProvider` | `StreamProvider<List<Debt>>` | Stream de deudas ordenadas por `interestRate DESC` |

## Método Avalanche
Las deudas se ordenan automáticamente por `interestRate DESC` en la query de AppDatabase.
La primera deuda en la lista siempre es el objetivo actual del método avalanche.

## AddGoalSheet
BottomSheet con 2 campos (nombre, monto objetivo) e inserción directa en Drift.
Se puede extender agregando selector de tipo, color, y deadline.

## Archivos Relacionados
- `goals_screen.dart` — UI completa
- `lib/core/widgets/shared_widgets.dart` — ProgressRing, LinearProgressBar
