import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// AUREA — Design System Tokens
// Mapeados directamente del DESIGN.md (Premium Finance System)
// ---------------------------------------------------------------------------

abstract class AppColors {
  // Backgrounds & Surfaces
  static const background = Color(0xFF14140F);
  static const surfaceDim = Color(0xFF14140F);
  static const surfaceContainerLowest = Color(0xFF0F0E0A);
  static const surfaceContainerLow = Color(0xFF1C1C16);
  static const surfaceContainer = Color(0xFF20201A);
  static const surfaceContainerHigh = Color(0xFF2B2A24);
  static const surfaceContainerHighest = Color(0xFF36352F);
  static const surfaceVariant = Color(0xFF36352F);
  static const surfaceBright = Color(0xFF3A3933);

  // On-Surface
  static const onBackground = Color(0xFFE6E2D9);
  static const onSurface = Color(0xFFE6E2D9);
  static const onSurfaceVariant = Color(0xFFC7C6CA);
  static const inverseSurface = Color(0xFFE6E2D9);
  static const inverseOnSurface = Color(0xFF31302B);

  // Outline
  static const outline = Color(0xFF919095);
  static const outlineVariant = Color(0xFF46464A);

  // Primary (Graphite)
  static const primary = Color(0xFFC8C6C8);
  static const onPrimary = Color(0xFF303032);
  static const primaryContainer = Color(0xFF1C1C1E);
  static const onPrimaryContainer = Color(0xFF858486);
  static const inversePrimary = Color(0xFF5F5E60);
  static const primaryFixed = Color(0xFFE4E2E4);
  static const primaryFixedDim = Color(0xFFC8C6C8);
  static const onPrimaryFixed = Color(0xFF1B1B1D);
  static const onPrimaryFixedVariant = Color(0xFF474649);

  // Secondary (Emerald Green) — Crecimiento, saldos positivos
  static const secondary = Color(0xFFA7D1AF);
  static const onSecondary = Color(0xFF123720);
  static const secondaryContainer = Color(0xFF2C5137);
  static const onSecondaryContainer = Color(0xFF99C2A1);
  static const secondaryFixed = Color(0xFFC2EDCA);
  static const secondaryFixedDim = Color(0xFFA7D1AF);
  static const onSecondaryFixed = Color(0xFF00210E);
  static const onSecondaryFixedVariant = Color(0xFF294E35);

  // Tertiary (Aged Gold) — Premium, activos, insights
  static const tertiary = Color(0xFFECC246);
  static const onTertiary = Color(0xFF3D2E00);
  static const tertiaryContainer = Color(0xFFCEA72C);
  static const onTertiaryContainer = Color(0xFF503D00);
  static const tertiaryFixed = Color(0xFFFFE08E);
  static const tertiaryFixedDim = Color(0xFFECC246);
  static const onTertiaryFixed = Color(0xFF241A00);
  static const onTertiaryFixedVariant = Color(0xFF584400);

  // Error (Terracotta) — Deudas, gastos, alertas
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  // Surface tint
  static const surfaceTint = Color(0xFFC8C6C8);

  // Convenience
  static const positiveGreen = secondary;
  static const agedGold = tertiary;
  static const terracotta = error;
}

abstract class AppTextStyles {
  // Display LG — IBM Plex Sans 48/56 w600 ls-2%
  static TextStyle displayLg(BuildContext context) =>
      GoogleFonts.ibmPlexSans(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        color: AppColors.onSurface,
      );

  // Headline LG — IBM Plex Sans 32/40 w600
  static TextStyle headlineLg(BuildContext context) =>
      GoogleFonts.ibmPlexSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        color: AppColors.onSurface,
      );

  // Headline LG Mobile — IBM Plex Sans 28/36 w600
  static TextStyle headlineLgMobile(BuildContext context) =>
      GoogleFonts.ibmPlexSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 36 / 28,
        color: AppColors.onSurface,
      );

  // Title MD — IBM Plex Sans 20/28 w500
  static TextStyle titleMd(BuildContext context) =>
      GoogleFonts.ibmPlexSans(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 28 / 20,
        color: AppColors.onSurface,
      );

  // Body LG — Inter 16/24 w400
  static TextStyle bodyLg(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      );

  // Body MD — Inter 14/20 w400
  static TextStyle bodyMd(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.onSurface,
      );

  // Label MD — IBM Plex Sans 12/16 w500 ls5%
  static TextStyle labelMd(BuildContext context) =>
      GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        color: AppColors.onSurface,
      );

  // Numeric Display — Inter 24/32 w600 ls-1%
  static TextStyle numericDisplay(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
        color: AppColors.onSurface,
      );

  // Numeric Display Large — Inter 48/56 w600 ls-2%
  static TextStyle numericDisplayLg(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        color: AppColors.onSurface,
      );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surfaceContainer,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
      ),
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      // Card
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.onSurface.withOpacity(0.05),
          ),
        ),
      ),
      // Bottom Nav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLow.withOpacity(0.85),
        indicatorColor: AppColors.surfaceVariant.withOpacity(0.5),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.tertiary, size: 24);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.tertiary,
            );
          }
          return GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedIconTheme: const IconThemeData(color: AppColors.tertiary),
        unselectedIconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
        indicatorColor: AppColors.surfaceVariant.withOpacity(0.4),
        elevation: 0,
        useIndicator: true,
      ),
      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.onSurface.withOpacity(0.08),
        thickness: 1,
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant.withOpacity(0.5),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tertiary,
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
