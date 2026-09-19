import 'package:flutter/material.dart';

abstract final class LurcSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class LurcTheme {
  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final scheme = brightness == Brightness.dark
        ? const ColorScheme.dark(
            primary: Color(0xFFF5F5F5),
            onPrimary: Color(0xFF111111),
            primaryContainer: Color(0xFF2A2A2A),
            onPrimaryContainer: Color(0xFFF5F5F5),
            secondary: Color(0xFFD4D4D4),
            onSecondary: Color(0xFF171717),
            secondaryContainer: Color(0xFF262626),
            onSecondaryContainer: Color(0xFFE5E5E5),
            error: Color(0xFFFF6B6B),
            onError: Color(0xFF1A0000),
            surface: Color(0xFF0D0D0D),
            onSurface: Color(0xFFF5F5F5),
            surfaceContainerLowest: Color(0xFF111111),
            surfaceContainerLow: Color(0xFF151515),
            surfaceContainer: Color(0xFF1A1A1A),
            surfaceContainerHigh: Color(0xFF202020),
            surfaceContainerHighest: Color(0xFF262626),
            onSurfaceVariant: Color(0xFFA3A3A3),
            outline: Color(0xFF525252),
            outlineVariant: Color(0xFF2B2B2B),
            inverseSurface: Color(0xFFF5F5F5),
            onInverseSurface: Color(0xFF171717),
          )
        : const ColorScheme.light(
            primary: Color(0xFF171717),
            onPrimary: Color(0xFFFFFFFF),
            primaryContainer: Color(0xFFE8E8E8),
            onPrimaryContainer: Color(0xFF171717),
            secondary: Color(0xFF525252),
            onSecondary: Color(0xFFFFFFFF),
            secondaryContainer: Color(0xFFEDEDED),
            onSecondaryContainer: Color(0xFF262626),
            error: Color(0xFFB42318),
            onError: Color(0xFFFFFFFF),
            surface: Color(0xFFF7F7F7),
            onSurface: Color(0xFF171717),
            surfaceContainerLowest: Color(0xFFFFFFFF),
            surfaceContainerLow: Color(0xFFF2F2F2),
            surfaceContainer: Color(0xFFEDEDED),
            surfaceContainerHigh: Color(0xFFE7E7E7),
            surfaceContainerHighest: Color(0xFFE0E0E0),
            onSurfaceVariant: Color(0xFF666666),
            outline: Color(0xFF8A8A8A),
            outlineVariant: Color(0xFFE2E2E2),
            inverseSurface: Color(0xFF202020),
            onInverseSurface: Color(0xFFF5F5F5),
          );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LurcSpacing.lg,
          vertical: LurcSpacing.md,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: scheme.outlineVariant,
        indicatorColor: scheme.primary,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: base.textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
    );
  }
}
