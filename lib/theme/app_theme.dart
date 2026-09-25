import 'package:flutter/material.dart';

import 'app_button_styles.dart';
import 'app_color_roles.dart';
import 'app_colors.dart';
import 'app_palettes.dart';

/// App-wide theme, in a light and (since 2026-09-25) a dark version: one
/// background everywhere, with the chosen color theme
/// ([AppPalette], picked in Settings; Cerulean blue by default) driving
/// every interactive element —
/// buttons, selected/toggled states, and hover/focus/splash
/// overlays — consistently across every screen. Light mode is white with
/// iron grey text and icons; dark mode is charcoal with off-white text and
/// light grey icons, and uses each color theme's lighter accent (see
/// [AppPalette.darkAccent]). Red/gold/green (star, correct/incorrect, danger) are
/// deliberately NOT wired into the general theme — they're semantic
/// highlight colors applied explicitly where they mean something specific
/// (see [AppColors]), not a "secondary" or "error" role every widget picks
/// up automatically.
///
/// Every color value here comes from [AppRawColors] or the palette; none
/// is written out in this file (see the note at the top of
/// `app_colors.dart`).
class AppTheme {
  const AppTheme._();

  static final Map<String, ThemeData> _cache = {};

  /// The light theme for [palette] (built once per palette, then reused).
  static ThemeData light([AppPalette palette = AppPalette.cerulean]) =>
      _cache.putIfAbsent(
          palette.id, () => _build(palette, _ModeColors.light(palette)));

  /// The dark theme for [palette]. A palette that isn't
  /// [AppPalette.darkReady] gets the default's dark theme instead.
  static ThemeData dark([AppPalette palette = AppPalette.cerulean]) {
    final used = palette.forDarkMode;
    return _cache.putIfAbsent('${used.id}-dark',
        () => _build(used, _ModeColors.dark(used)));
  }

  /// One builder for both modes, so they can't drift apart: everything that
  /// differs between light and dark is in [_ModeColors].
  static ThemeData _build(AppPalette palette, _ModeColors mode) {
    final accent = mode.accent;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: mode.fieldBorder, width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: accent, width: 2),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: mode.brightness,
      primary: accent,
      onPrimary: mode.onAccent,
      secondary: mode.secondary,
      onSecondary: mode.onAccent,
      tertiary: palette.tertiary,
      onTertiary: mode.onAccent,
      error: AppRawColors.brickRed,
      onError: AppRawColors.white,
      surface: mode.background,
      onSurface: mode.text,
      primaryContainer: mode.accentContainer,
      onPrimaryContainer: mode.onAccentContainer,
    );

    final baseText = mode.brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: mode.brightness,
      colorScheme: colorScheme,
      // The colors the Material theme has no slot for (inactive grey, the
      // "on" filter look, box borders, ink). Read with `context.appColors`.
      extensions: [mode.roles],
      scaffoldBackgroundColor: mode.background,
      canvasColor: mode.background,
      hoverColor: accent.withValues(alpha: 0.08),
      focusColor: accent.withValues(alpha: 0.12),
      splashColor: accent.withValues(alpha: 0.12),
      highlightColor: accent.withValues(alpha: 0.08),
      dividerColor: mode.text.withValues(alpha: 0.2),
      iconTheme: IconThemeData(color: mode.icon),
      textTheme: baseText.apply(
        bodyColor: mode.text,
        displayColor: mode.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: mode.background,
        foregroundColor: mode.text,
        surfaceTintColor: mode.background,
        elevation: 0,
        iconTheme: IconThemeData(color: mode.icon),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: mode.onAccent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: mode.onAccent,
        ),
      ),
      // The tag chip look whenever hovered, pressed or focused.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.outlined(colorScheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: mode.onAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
      ),
    );
  }
}

/// Everything that differs between the light and dark theme, side by side.
class _ModeColors {
  const _ModeColors({
    required this.brightness,
    required this.accent,
    required this.onAccent,
    required this.secondary,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.background,
    required this.text,
    required this.icon,
    required this.fieldBorder,
    required this.roles,
  });

  /// Exactly the app's look before dark mode existed.
  factory _ModeColors.light(AppPalette palette) => _ModeColors(
        brightness: Brightness.light,
        accent: palette.primary,
        onAccent: AppRawColors.white,
        secondary: palette.secondary,
        accentContainer: palette.container,
        // Near-black on the tint, mirroring off-white on dark mode's
        // (10.8–12.3:1 across the 8 themes; was the theme's deep shade).
        onAccentContainer: AppRawColors.nearBlack,
        background: AppRawColors.white,
        text: AppRawColors.ironGrey,
        icon: AppRawColors.ironGrey,
        fieldBorder: AppRawColors.ironGrey,
        roles: AppColorRoles.light,
      );

  /// Charcoal background, off-white text, light grey icons, and the
  /// palette's lighter accent with near-black text on it (white on the
  /// light accents is too faint).
  factory _ModeColors.dark(AppPalette palette) => _ModeColors(
        brightness: Brightness.dark,
        accent: palette.darkAccent,
        onAccent: AppRawColors.nearBlack,
        secondary: palette.darkAccent,
        accentContainer:
            Color.lerp(palette.darkAccent, AppRawColors.charcoal, 0.7)!,
        onAccentContainer: AppRawColors.offWhite,
        background: AppRawColors.charcoal,
        text: AppRawColors.offWhite,
        icon: AppRawColors.lightGrey,
        fieldBorder: AppRawColors.ashGrey,
        roles: AppColorRoles.dark,
      );

  final Brightness brightness;
  final Color accent;
  final Color onAccent;
  final Color secondary;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color background;
  final Color text;
  final Color icon;
  final Color fieldBorder;
  final AppColorRoles roles;
}
