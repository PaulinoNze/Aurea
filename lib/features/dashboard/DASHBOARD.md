# DASHBOARD.md — Pantalla Dashboard
<!--
  Documenta la pantalla Dashboard. Lee antes de modificar dashboard_screen.dart o dashboard_providers.dart.
-->

## Componentes Visuales
1. **Net Worth Section** — Número grande con color `tertiary` (Gold). Fuente Inter 40px w600.
2. **Horizontal Cards** — ListView horizontal con 2 cards de 280px de ancho:
   - Card 1: "Ingresos vs Gastos" con barras de progreso animadas
   - Card 2: "Presupuesto Restante" con barra dorada y porcentaje
3. **Donut Chart** — `PieChart` de fl_chart, 4 segmentos (Vivienda, Alimentos, Ocio, Otros), centerspaceRadius=55
4. **Recent Activity** — Últimas 5 transacciones con CategoryIcon, note, fecha, y AmountText coloreado

## Providers
| Provider | Tipo | Descripción |
|---|---|---|
| `netWorthProvider` | `Provider<double>` | Valor hardcodeado (1,245,000) — demo |
| `monthlyIncomeProvider` | `StreamProvider<double>` | Suma de ingresos del mes actual |
| `monthlyExpensesProvider` | `StreamProvider<double>` | Suma de gastos del mes actual |
| `recentTransactionsProvider` | `StreamProvider<List<Transaction>>` | Últimas 10 transacciones |
| `categoriesProvider` | `StreamProvider<List<Category>>` | Todas las categorías |

## Layout Responsive
- **Móvil (< 800px)**: `_DonutChartCard` arriba, `_RecentActivityCard` abajo (columna)
- **Wide (>= 800px)**: Ambas en fila (ratio 2:1)

## Colores de Categorías en el Donut
| Segmento | Color Flutter |
|---|---|
| Vivienda (40%) | `AppColors.tertiary` |
| Alimentos (25%) | `AppColors.secondary` |
| Ocio (20%) | `AppColors.error` |
| Otros (15%) | `AppColors.inversePrimary` |

## Archivos Relacionados
- `dashboard_screen.dart` — UI principal
- `dashboard_providers.dart` — StreamProviders de Riverpod
