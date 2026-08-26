# BUDGET.md — Pantalla Presupuestos y Análisis

## Componentes Visuales

### BudgetScreen
- **Period Selector**: Toggle pill (Semanal / Mensual / Anual), estado en `_periodProvider`
- **Layout**: Columna en móvil, 2 columnas (2:1) en wide (>= 700px)

### _BudgetCategories (columna izquierda)
Lista de 4 categorías hardcodeadas con datos `_budgetData`:
| Categoría | Usado | Total | Color barra |
|---|---|---|---|
| Comida y Restaurantes | $850 | $1,000 | `secondary` |
| Transporte | $160 | $400 | `primary` |
| Compras | $230 | $300 | `tertiary` |
| Vivienda | $1,200 | $1,500 | `error` |

Cuando `pct >= 90%`, el color de la barra cambia automáticamente a `AppColors.error`.

### _SpendingAnalysis (columna derecha)
- **Resumen del Mes**: 3 filas (Total Presupuestado, Total Gastado, Restante) + barra
- **Gastos por Semana**: `BarChart` fl_chart con 4 barras (S1-S4), color `secondary`/`tertiary` para semana actual

## Provider
| Provider | Tipo | Descripción |
|---|---|---|
| `_periodProvider` | `StateProvider<_BudgetPeriod>` | Filtro de período |

## Datos
Los datos actuales son estáticos (demo). Para hacer los datos dinámicos:
1. Agregar query en AppDatabase para agrupar gastos por categoría/período
2. Crear provider con `StreamProvider` que combina `budgets` y `transactions`
3. Reemplazar `_budgetData` constante con datos del provider

## Archivos Relacionados
- `budget_screen.dart` — UI completa
