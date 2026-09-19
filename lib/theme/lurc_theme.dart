import 'package:flutter/material.dart';

abstract final class LurcColors {
  static const navy = Color(0xFF12203A);
  static const emerald = Color(0xFF34D399);
  static const offWhite = Color(0xFFEAF0F8);
}

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
            primary: LurcColors.emerald,
            onPrimary: LurcColors.navy,
            primaryContainer: Color(0xFF173C34),
            onPrimaryContainer: Color(0xFFC9FBE8),
            secondary: LurcColors.offWhite,
            onSecondary: LurcColors.navy,
            secondaryContainer: Color(0xFF23324A),
            onSecondaryContainer: LurcColors.offWhite,
            error: Color(0xFFFF6B6B),
            onError: Color(0xFF260000),
            surface: Color(0xFF0D1728),
            onSurface: LurcColors.offWhite,
            surfaceContainerLowest: Color(0xFF09111E),
            surfaceContainerLow: LurcColors.navy,
            surfaceContainer: Color(0xFF182742),
            surfaceContainerHigh: Color(0xFF20314F),
            surfaceContainerHighest: Color(0xFF29405F),
            onSurfaceVariant: Color(0xFFB6C1D0),
            outline: Color(0xFF65758D),
            outlineVariant: Color(0xFF2D405D),
            inverseSurface: LurcColors.offWhite,
            onInverseSurface: LurcColors.navy,
          )
        : const ColorScheme.light(
            primary: LurcColors.emerald,
            onPrimary: LurcColors.navy,
            primaryContainer: Color(0xFFCFF8E7),
            onPrimaryContainer: LurcColors.navy,
            secondary: LurcColors.navy,
            onSecondary: LurcColors.offWhite,
            secondaryContainer: Color(0xFFDDE5F0),
            onSecondaryContainer: LurcColors.navy,
            error: Color(0xFFB42318),
            onError: Color(0xFFFFFFFF),
            surface: Color(0xFFF7F9FC),
            onSurface: LurcColors.navy,
            surfaceContainerLowest: Color(0xFFFFFFFF),
            surfaceContainerLow: Color(0xFFF0F4F8),
            surfaceContainer: Color(0xFFE8EDF4),
            surfaceContainerHigh: Color(0xFFE0E7F0),
            surfaceContainerHighest: Color(0xFFD7E0EB),
            onSurfaceVariant: Color(0xFF526176),
            outline: Color(0xFF75849A),
            outlineVariant: Color(0xFFD2DAE5),
            inverseSurface: LurcColors.navy,
            onInverseSurface: LurcColors.offWhite,
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
        indicatorColor: scheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
