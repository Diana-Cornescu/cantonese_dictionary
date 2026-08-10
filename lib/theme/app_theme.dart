import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide theme: a white surface everywhere, with the blue family
/// (cerulean/cobaltBlue/tropicalTeal) driving every interactive element —
/// buttons, the FAB, selected/toggled states, and hover/focus/splash
/// overlays — consistently across every screen. Default icons and text are
/// iron grey. Red/gold/green (star, correct/incorrect, danger) are
/// deliberately NOT wired into the general theme — they're semantic
/// highlight colors applied explicitly where they mean something specific
/// (see [AppColors]), not a "secondary" or "error" role every widget picks
/// up automatically.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.ironGrey, width: 1),
    );
    const focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.cerulean, width: 2),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.cerulean,
      brightness: Brightness.light,
      primary: AppColors.cerulean,
      onPrimary: Colors.white,
      secondary: AppColors.cobaltBlue,
      onSecondary: Colors.white,
      tertiary: AppColors.tropicalTeal,
      onTertiary: Colors.white,
      error: AppColors.brickRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ironGrey,
      primaryContainer: const Color(0xFFDCEBF5),
      onPrimaryContainer: AppColors.cobaltBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      hoverColor: AppColors.cerulean.withOpacity(0.08),
      focusColor: AppColors.cerulean.withOpacity(0.12),
      splashColor: AppColors.cerulean.withOpacity(0.12),
      highlightColor: AppColors.cerulean.withOpacity(0.08),
      dividerColor: AppColors.ironGrey.withOpacity(0.2),
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
          backgroundColor: AppColors.cerulean,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cerulean,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cerulean,
          side: const BorderSide(color: AppColors.cerulean),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.cerulean),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cerulean,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
      ),
    );
  }
}
