---
name: Premium Finance System
colors:
  surface: '#14140f'
  surface-dim: '#14140f'
  surface-bright: '#3a3933'
  surface-container-lowest: '#0f0e0a'
  surface-container-low: '#1c1c16'
  surface-container: '#20201a'
  surface-container-high: '#2b2a24'
  surface-container-highest: '#36352f'
  on-surface: '#e6e2d9'
  on-surface-variant: '#c7c6ca'
  inverse-surface: '#e6e2d9'
  inverse-on-surface: '#31302b'
  outline: '#919095'
  outline-variant: '#46464a'
  surface-tint: '#c8c6c8'
  primary: '#c8c6c8'
  on-primary: '#303032'
  primary-container: '#1c1c1e'
  on-primary-container: '#858486'
  inverse-primary: '#5f5e60'
  secondary: '#a7d1af'
  on-secondary: '#123720'
  secondary-container: '#2c5137'
  on-secondary-container: '#99c2a1'
  tertiary: '#ecc246'
  on-tertiary: '#3d2e00'
  tertiary-container: '#cea72c'
  on-tertiary-container: '#503d00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e4e2e4'
  primary-fixed-dim: '#c8c6c8'
  on-primary-fixed: '#1b1b1d'
  on-primary-fixed-variant: '#474649'
  secondary-fixed: '#c2edca'
  secondary-fixed-dim: '#a7d1af'
  on-secondary-fixed: '#00210e'
  on-secondary-fixed-variant: '#294e35'
  tertiary-fixed: '#ffe08e'
  tertiary-fixed-dim: '#ecc246'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#584400'
  background: '#14140f'
  on-background: '#e6e2d9'
  surface-variant: '#36352f'
typography:
  display-lg:
    fontFamily: IBM Plex Sans
    fontSize: 48px
    fontWeight: '600'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: IBM Plex Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-md:
    fontFamily: IBM Plex Sans
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  numeric-display:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 40px
---

## Brand & Style

The design system is engineered for a premium personal finance experience that prioritizes clarity, sobriety, and a sense of established wealth. The brand personality is that of a "Trusted Private Banker"—professional, discreet, and highly organized. It aims to evoke a feeling of calm control over complex financial data.

The design style is **Corporate / Modern** with a **Minimalist** finish. It utilizes a Material 3 architectural foundation but strips away excessive ornamentation in favor of high-quality typography and a disciplined color application. Dark mode is the primary orientation, using depth and tonal layering rather than heavy shadows to establish hierarchy. Micro-interactions should be purposeful and dampened, favoring smooth transitions over energetic bounces.

## Colors

This design system utilizes a sophisticated, low-chroma palette to maintain a professional atmosphere.

- **Primary (Graphite):** The structural foundation. In dark mode, this serves as the "Surface" and "Background" color.
- **Secondary (Emerald Green):** Used exclusively for growth, positive balances, and successful actions. It signifies financial health.
- **Highlight (Aged Gold):** Reserved for premium features, high-value insights, and active states. Use sparingly to maintain its impact.
- **Neutral (Ivory/Cream):** The primary text color in dark mode and the background color for the light mode variant.
- **Alert (Terracotta):** A muted, earthy red used for debts, expenses, and warnings, ensuring the UI remains "sober" even during alerts.

**Color Application:**
Use the Emerald and Gold primarily as accents on structural Graphite surfaces. Avoid large flood-fills of these colors to prevent the UI from feeling loud or unrefined.

## Typography

The system uses a dual-font approach to maximize readability and technical precision.

- **IBM Plex Sans** is used for headlines, titles, and labels. Its technical, slightly engineered feel reinforces the "professional tool" aspect of the system.
- **Inter** is used for body copy and all numeric data. Inter’s tall x-height and neutral character make it ideal for dense transaction lists and complex financial tables.

**Numeric Styling:**
Financial figures should always use tabular lining figures if available, ensuring that decimals and commas align vertically in lists. For large balances, use the `numeric-display` style with `display-lg` for total net worth views.

## Layout & Spacing

The design system employs a **Fluid Grid** model based on an 8px spacing rhythm. 

- **Mobile:** 4-column grid with 20px side margins and 16px gutters.
- **Tablet/Desktop:** 12-column grid with 40px side margins. For wide screens, content is contained within a 1200px max-width container.

Spacing should prioritize "breathing room" between logical sections to reduce cognitive load when viewing data. Use `lg` (24px) or `xl` (32px) padding for card containers to ensure information doesn't feel cramped.

## Elevation & Depth

This design system avoids traditional drop shadows. Instead, it uses **Tonal Layers** and **Low-contrast Outlines** to define hierarchy.

1.  **Level 0 (Background):** Pure Graphite (#1C1C1E).
2.  **Level 1 (Cards/Surfaces):** A slightly lighter Graphite (approx. 5% lighter) or a semi-transparent white overlay (2-4% opacity) over the background.
3.  **Level 2 (Modals/Popovers):** Surface color with a subtle 1px stroke using Ivory at 10% opacity.
4.  **Interaction:** Elements "lift" by increasing the opacity of their surface overlay rather than casting a shadow.

For charts, use subtle background blurs behind floating tooltips to maintain legibility without breaking the flat aesthetic.

## Shapes

The shape language is sophisticated and modern, using generous rounding to soften the "technical" nature of financial data.

- **Standard Components:** Buttons, input fields, and small chips use a `0.5rem` (8px) radius.
- **Containers:** Primary dashboard cards and transaction modules use `rounded-xl` (1.5rem / 24px) to create a distinct, high-end feel.
- **Selection States:** Use pill-shapes (3) for toggle switches and navigation indicators to provide a clear contrast against rectangular data cards.

## Components

### Cards & Transactions
Transaction cards should be flat with a 1px border (`Ivory` at 5% opacity). Icons for categories should be monochromatic, contained within an `Emerald Green` or `Graphite` circular container.

### Charts (fl_chart style)
Line charts should use a "smooth" Bezier curve. The area below the line should have a subtle gradient from `Emerald Green` (at 10% opacity) to transparent. Grid lines must be minimal, using the Alert `Terracotta` only for "budget exceeded" thresholds.

### Navigation
- **Mobile:** A bottom navigation bar with a glassmorphism effect (backdrop blur: 20px). Icons use the Highlight `Aged Gold` for the active state.
- **Desktop:** A narrow Navigation Rail on the left, keeping the center stage clear for data visualization.

### Buttons & Inputs
- **Primary Button:** Solid `Emerald Green` with `Ivory` text.
- **Secondary Button:** Ghost style with `Ivory` 1px border.
- **Inputs:** Underlined or subtly boxed with 5% white fill. The label should float to `label-md` on focus.

### Biometric Pattern
The lock screen should be a clean `Graphite` surface. The biometric icon (FaceID/Fingerprint) should pulsate softly in `Aged Gold` when active, using a circular stroke animation.