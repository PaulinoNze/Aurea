# THEME.md — Sistema de Diseño Aurea
<!--
  Este archivo documenta el sistema de diseño. 
  Antes de modificar app_theme.dart, lee este documento para no romper la consistencia visual.
-->

## Paleta de Colores (Premium Finance System)

| Token Flutter | Hex | Uso |
|---|---|---|
| `AppColors.background` | `#14140F` | Fondo principal de toda la app |
| `AppColors.surfaceContainerLow` | `#1C1C16` | Cards principales, bottom nav |
| `AppColors.surfaceContainer` | `#20201A` | Cards secundarias, listas |
| `AppColors.surfaceContainerHigh` | `#2B2A24` | Inputs, botones secundarios |
| `AppColors.surfaceVariant` | `#36352F` | Estados activos en nav, chips |
| `AppColors.onSurface` | `#E6E2D9` | Texto principal (Ivory) |
| `AppColors.onSurfaceVariant` | `#C7C6CA` | Texto secundario |
| `AppColors.secondary` | `#A7D1AF` | Emerald Green — ingresos, progreso, CTA principal |
| `AppColors.onSecondary` | `#123720` | Texto sobre secondary |
| `AppColors.secondaryContainer` | `#2C5137` | Fondo de iconos de categoría activos |
| `AppColors.tertiary` | `#ECC246` | Aged Gold — nav activo, premium, highlights |
| `AppColors.onTertiary` | `#3D2E00` | Texto sobre tertiary |
| `AppColors.error` | `#FFB4AB` | Terracotta — deudas, gastos, alertas |
| `AppColors.errorContainer` | `#93000A` | Fondo de alertas de error |
| `AppColors.outline` | `#919095` | Bordes principales |
| `AppColors.outlineVariant` | `#46464A` | Bordes sutiles, divisores |

## Tipografía

| Estilo | Fuente | Size | Weight | Uso |
|---|---|---|---|---|
| `displayLg` | IBM Plex Sans | 48px | 600 | Patrimonio neto (main figure) |
| `headlineLg` | IBM Plex Sans | 32px | 600 | Títulos de página (desktop) |
| `headlineLgMobile` | IBM Plex Sans | 28px | 600 | Títulos de página (móvil) |
| `titleMd` | IBM Plex Sans | 20px | 500 | Títulos de sección/card |
| `bodyLg` | Inter | 16px | 400 | Texto principal |
| `bodyMd` | Inter | 14px | 400 | Texto secundario, listas |
| `labelMd` | IBM Plex Sans | 12px | 500 | Labels, etiquetas, nav |
| `numericDisplay` | Inter | 24px | 600 | Cifras financieras intermedias |
| `numericDisplayLg` | Inter | 48px | 600 | Cifras financieras grandes |

## Espaciado (8px grid)
- `xs` = 4px
- `sm` = 12px
- `md` = 16px
- `lg` = 24px
- `xl` = 32px
- `margin-mobile` = 20px
- `margin-desktop` = 40px

## Border Radius
- Botones small, chips: `8px`
- Cards, contenedores: `16px` (rounded-xl)
- Botones principales (CTA): `999px` (pill)

## Elevación (sin sombras reales)
Se usa **Tonal Layering** en lugar de shadows:
- Level 0 (background): `#14140F`
- Level 1 (cards): `#1C1C16` + border `onSurface` al 5% opacity
- Level 2 (modals): `#20201A` + border `onSurface` al 10% opacity
- Interacción: aumentar opacity del overlay (no shadow)

## Reglas de Uso de Color
1. Nunca usar `secondary` o `tertiary` como fondo de área grande
2. `tertiary` (Gold) solo para estado activo en navegación y highlights premium
3. `secondary` (Green) para CTAs, ingresos positivos, y progreso
4. `error` (Terracotta) para deudas y gastos - mantener tono sobrio

## Archivos Relacionados
- `app_theme.dart` — AppColors, AppTextStyles, AppTheme.darkTheme
