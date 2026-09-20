import 'package:flutter/material.dart';

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
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String id;
  final String name;

  /// Buttons, selected states, focus.
  final Color primary;

  /// A deeper shade, used for text on light tinted backgrounds.
  final Color secondary;

  /// A lighter accent.
  final Color tertiary;

  /// A very light tint of [primary] for container backgrounds.
  Color get container => Color.lerp(primary, Colors.white, 0.85)!;

  static const cerulean = AppPalette(
    id: 'cerulean',
    name: 'Cerulean',
    primary: Color(0xFF207BAC),
    secondary: Color(0xFF204CAC),
    tertiary: Color(0xFF20AAAC),
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
    ),
    AppPalette(
      id: 'violet',
      name: 'Violet',
      primary: Color(0xFF6B3FA0),
      secondary: Color(0xFF4E2C78),
      tertiary: Color(0xFF8E6BC4),
    ),
    AppPalette(
      id: 'plum',
      name: 'Plum',
      primary: Color(0xFF86398C),
      secondary: Color(0xFF632A68),
      tertiary: Color(0xFFAA62B0),
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
