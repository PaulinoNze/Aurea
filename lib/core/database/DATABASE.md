# DATABASE.md — Schema de Base de Datos Aurea (Drift/SQLite)
<!--
  Documenta el schema Drift. Antes de agregar/modificar tablas, lee este archivo.
  Los cambios de schema DEBEN incrementar schemaVersion en AppDatabase.
-->

## Tablas

### `categories`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | ID único |
| `name` | TEXT | Nombre de la categoría |
| `icon_code` | INTEGER | codePoint del icono Material (e.g. `Icons.restaurant.codePoint`) |
| `color_hex` | TEXT | Color en hex `#RRGGBB` |
| `budget_limit` | REAL NULL | Límite de presupuesto mensual (null = sin límite) |

### `transactions`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | ID único |
| `amount` | REAL | Monto de la transacción |
| `category_id` | INTEGER FK→categories | Categoría |
| `type` | TEXT | `'expense'` o `'income'` |
| `date` | DATETIME | Fecha y hora de la transacción |
| `note` | TEXT | Nota o descripción |
| `sync_status` | TEXT | `'pending'` o `'synced'` |
| `updated_at` | DATETIME | Timestamp de última modificación (para LWW) |

### `budgets`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | ID único |
| `category_id` | INTEGER FK→categories | Categoría del presupuesto |
| `amount` | REAL | Monto del presupuesto |
| `period` | TEXT | `'weekly'`, `'monthly'`, o `'yearly'` |

### `savings_goals`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | ID único |
| `name` | TEXT | Nombre de la meta |
| `goal_type` | TEXT | `'savings'`, `'vacation'`, `'emergency'` |
| `target_amount` | REAL | Monto objetivo |
| `current_amount` | REAL | Monto ahorrado actualmente |
| `deadline` | DATETIME NULL | Fecha límite (opcional) |
| `color_index` | INTEGER | 0=secondary(green), 1=tertiary(gold), 2=error(red) |

### `debts`
| Campo | Tipo | Descripción |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | ID único |
| `name` | TEXT | Nombre de la deuda |
| `interest_rate` | REAL | APR en porcentaje (e.g. 22.99) |
| `remaining_amount` | REAL | Monto restante |
| `minimum_payment` | REAL | Pago mínimo mensual |
| `extra_payment` | REAL | Pago extra (método avalanche/snowball) |
| `method` | TEXT | `'avalanche'` (mayor interés) o `'snowball'` (menor monto) |
| `icon_code` | INTEGER | codePoint del icono |

## Schema Version: 1

## Reglas de Migración
1. Cualquier cambio de schema DEBE incrementar `schemaVersion` en `AppDatabase`
2. Agregar un caso en `MigrationStrategy.onUpgrade`
3. NUNCA cambiar el nombre de una columna existente sin migración
4. Para agregar columnas opcionales, usar `.nullable()` o `.withDefault()`

## Providers Riverpod
- `databaseProvider` — Singleton AppDatabase en `database_provider.dart`
- Todos los features importan `databaseProvider` para acceder a los streams/queries

## Archivos Relacionados
- `app_database.dart` — Definición de tablas, AppDatabase, seed data
- `database_provider.dart` — Provider Riverpod
- `app_database.g.dart` — Generado por `build_runner` (NO editar manualmente)
