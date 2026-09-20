import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palettes.dart';

/// App-wide theme: a white surface everywhere, with the chosen color theme
/// ([AppPalette], picked in Settings; Cerulean blue by default) driving
/// every interactive element —
/// buttons, the FAB, selected/toggled states, and hover/focus/splash
/// overlays — consistently across every screen. Default icons and text are
/// iron grey. Red/gold/green (star, correct/incorrect, danger) are
/// deliberately NOT wired into the general theme — they're semantic
/// highlight colors applied explicitly where they mean something specific
/// (see [AppColors]), not a "secondary" or "error" role every widget picks
/// up automatically.
class AppTheme {
  const AppTheme._();

  static final Map<String, ThemeData> _cache = {};

  /// The theme for [palette] (built once per palette, then reused).
  static ThemeData light([AppPalette palette = AppPalette.cerulean]) =>
      _cache.putIfAbsent(palette.id, () => _build(palette));

  static ThemeData _build(AppPalette palette) {
    final primary = palette.primary;
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.ironGrey, width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: primary, width: 2),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: palette.secondary,
      onSecondary: Colors.white,
      tertiary: palette.tertiary,
      onTertiary: Colors.white,
      error: AppColors.brickRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ironGrey,
      primaryContainer: palette.container,
      onPrimaryContainer: palette.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      hoverColor: primary.withValues(alpha: 0.08),
      focusColor: primary.withValues(alpha: 0.12),
      splashColor: primary.withValues(alpha: 0.12),
      highlightColor: primary.withValues(alpha: 0.08),
      dividerColor: AppColors.ironGrey.withValues(alpha: 0.2),
      iconTheme: const IconThemeData(color: AppColors.ironGrey),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.ironGrey,
            displayColor: AppColors.ironGrey,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ironGrey,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ironGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
      ),
    );
  }
}
