# TRANSACTIONS.md — Pantallas de Transacciones
<!--
  Documenta ActivityScreen y NewTransactionScreen.
-->

## ActivityScreen (`activity_screen.dart`)

### Componentes
- **SearchBar**: TextField filtrado que busca en `note` y nombre de categoría
- **FilterChips**: Tres chips (Todos / Ingresos / Gastos), estado gestionado por `_filterProvider`
- **TransactionList**: Lista agrupada por fecha, con `_ActivityRow` por transacción

### Providers Locales
| Provider | Tipo | Descripción |
|---|---|---|
| `_filterProvider` | `StateProvider<_Filter>` | enum: all, income, expense |
| `_searchQueryProvider` | `StateProvider<String>` | Texto de búsqueda en minúsculas |

### Agrupación por Fecha
Las transacciones se agrupan usando `DateFormat('EEEE, d MMMM', 'es')`. Cada grupo se muestra en un `Container` con `BorderRadius.circular(16)`.

---

## NewTransactionScreen (`new_transaction_screen.dart`)

### Flujo de la pantalla
1. Toggle Gasto/Ingreso → cambia `_txTypeProvider`
2. Numpad → acumula `_amountStringProvider` (máx 10 caracteres, un solo `.`)
3. Category Selector → scroll horizontal, estado en `_selectedCategoryIndexProvider`
4. Note input → `_noteProvider`
5. Botón "Guardar Localmente" → inserta en Drift y cierra modal

### Providers Locales
| Provider | Tipo | Descripción |
|---|---|---|
| `_txTypeProvider` | `StateProvider<String>` | 'expense' o 'income' |
| `_selectedCategoryIndexProvider` | `StateProvider<int>` | Índice en `_kCategories` |
| `_amountStringProvider` | `StateProvider<String>` | String del monto (e.g. "12.50") |
| `_noteProvider` | `StateProvider<String>` | Nota de la transacción |

### Numpad
- Cada key tiene feedback háptico (`HapticFeedback.lightImpact()`)
- `_NumpadKey` tiene animación de escala al 93% en tap
- Backspace elimina último caracter; si queda 1 caracter lo resetea a '0'

### Categorías
- Lista constante `_kCategories` con 8 categorías (7 gasto + 1 ingreso)
- Al cambiar entre Gasto/Ingreso, se filtra la lista mostrada

### Navegación
- Se abre con `context.push(AppRoutes.newTransaction)` desde MainShell FAB
- Se cierra con `Navigator.of(context).pop()` (compatible con go_router)
- Transición: SlideTransition desde abajo (bottom sheet feel)

## Archivos Relacionados
- `activity_screen.dart` — ActivityScreen
- `new_transaction_screen.dart` — NewTransactionScreen
