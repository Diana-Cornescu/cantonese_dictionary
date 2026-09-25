import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The color themes you can pick in Settings (2026-09-20).
///
/// Every theme's hue is chosen to stay clearly apart from the colors that
/// already MEAN something in the app (see `AppColors`):
///   - red (🔥 hard, incorrect, delete)      ~0°
///   - gold/yellow (⭐ favorite, "mid" accuracy) ~40°
///   - green (correct, high accuracy)          ~140°
/// So there are deliberately no red, pink, orange, brown, yellow or green
/// themes: only blues, teal, purples and a neutral slate.
///
/// [id] is what's saved in the database; never rename an existing id.
///
/// This file is the one list of the themes' own colors, next to
/// [AppRawColors] for everything else (see the note at the top of
/// `app_colors.dart`).
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    this.darkReady = false,
  });

  final String id;
  final String name;

  /// Buttons, selected states, focus.
  final Color primary;

  /// A deeper shade, used for text on light tinted backgrounds.
  final Color secondary;

  /// A lighter accent.
  final Color tertiary;

  /// A light tint of [primary] (30% of it on white) for the tag chip look
  /// in light mode — the mirror of dark mode's 30% of [darkAccent] on
  /// charcoal (2026-09-25; was a fainter 15% before).
  Color get container => Color.lerp(primary, AppRawColors.white, 0.7)!;

  /// Whether this theme has a dark-mode version yet (2026-09-25).
  ///
  /// In dark mode the theme's color is its lighter [tertiary] accent, since
  /// the usual [primary] is too dark to read on a dark background. A theme
  /// is dark-ready when that accent is clear on the dark background: at
  /// least 4:1 contrast. `test/app_palettes_test.dart` checks the number,
  /// so a theme can't be marked ready if it isn't.
  ///
  /// Ready: Cerulean 5.9, Teal 5.6, Iris 4.3, Plum 4.1, Violet 4.0.
  /// Not yet: Slate 3.97 (just short), Cobalt 3.6, Navy 3.1 — their light
  /// accent is still too dark and would need a new one picked for dark
  /// mode. Until then, dark mode shows Cerulean for them, and Settings
  /// says so.
  final bool darkReady;

  /// The theme's main color in dark mode.
  Color get darkAccent => tertiary;

  /// The palette dark mode actually uses when this one is chosen: itself
  /// if [darkReady], otherwise the default.
  AppPalette get forDarkMode => darkReady ? this : cerulean;

  static const cerulean = AppPalette(
    id: 'cerulean',
    name: 'Cerulean',
    primary: Color(0xFF207BAC),
    secondary: Color(0xFF204CAC),
    tertiary: Color(0xFF20AAAC),
    darkReady: true,
  );

  static const all = <AppPalette>[
    cerulean, // the original look, and the default
    AppPalette(
      id: 'cobalt',
      name: 'Cobalt',
      primary: Color(0xFF204CAC),
      secondary: Color(0xFF17367D),
      tertiary: Color(0xFF207BAC),
    ),
    AppPalette(
      id: 'teal',
      name: 'Teal',
      // Leans blue on purpose (hue ~191°) to stay well away from the green
      // used for "correct".
      primary: Color(0xFF177C92),
      secondary: Color(0xFF0E5E6E),
      tertiary: Color(0xFF22A4B8),
      darkReady: true,
    ),
    AppPalette(
      id: 'navy',
      name: 'Navy',
      primary: Color(0xFF26406E),
      secondary: Color(0xFF182B4D),
      tertiary: Color(0xFF3C6E9E),
    ),
    AppPalette(
      id: 'iris',
      name: 'Iris',
      primary: Color(0xFF5054B8),
      secondary: Color(0xFF383B8C),
      tertiary: Color(0xFF7478D6),
      darkReady: true,
    ),
    AppPalette(
      id: 'violet',
      name: 'Violet',
      primary: Color(0xFF6B3FA0),
      secondary: Color(0xFF4E2C78),
      tertiary: Color(0xFF8E6BC4),
      darkReady: true,
    ),
    AppPalette(
      id: 'plum',
      name: 'Plum',
      primary: Color(0xFF86398C),
      secondary: Color(0xFF632A68),
      tertiary: Color(0xFFAA62B0),
      darkReady: true,
    ),
    AppPalette(
      id: 'slate',
      name: 'Slate',
      primary: Color(0xFF4F5B66),
      secondary: Color(0xFF36404A),
      tertiary: Color(0xFF6F7D89),
    ),
  ];

  /// The palette with [id], or the default if unknown/missing.
  static AppPalette byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return cerulean;
  }

  /// The key the chosen palette is saved under in the settings table.
  static const settingKey = 'color_theme';
}
