import 'package:cantonese_dictionary_app/theme/app_color_roles.dart';
import 'package:cantonese_dictionary_app/theme/app_colors.dart';
import 'package:cantonese_dictionary_app/theme/app_palettes.dart';
import 'package:cantonese_dictionary_app/theme/app_theme.dart';
import 'package:cantonese_dictionary_app/theme/app_theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shortest distance between two hues on the color wheel, in degrees.
double _hueGap(Color a, Color b) {
  final d = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue).abs();
  return d > 180 ? 360 - d : d;
}

/// WCAG contrast ratio between two colors (1 = none, 21 = black on white).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('palette ids are unique and unknown ids fall back to the default',
      () {
    final ids = AppPalette.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(AppPalette.byId('does-not-exist').id, AppPalette.cerulean.id);
    expect(AppPalette.byId(null).id, AppPalette.cerulean.id);
  });

  test('no theme color can be confused with red (hard), gold (favorite) '
      'or green (correct)', () {
    for (final palette in AppPalette.all) {
      final hsv = HSVColor.fromColor(palette.primary);
      // Near-grey themes (like Slate) carry almost no hue, so they can't
      // be mistaken for any of the meaning colors.
      if (hsv.saturation < 0.3) continue;
      for (final meaning in [
        AppColors.danger,
        AppColors.star,
        AppColors.success,
      ]) {
        expect(_hueGap(palette.primary, meaning), greaterThan(45),
            reason: '${palette.name} is too close to $meaning');
      }
    }
  });

  // ---- Dark mode (2026-09-25) ---------------------------------------------

  test('a theme is marked dark-ready exactly when its dark accent is clear '
      'on the dark background (at least 4:1)', () {
    for (final palette in AppPalette.all) {
      final ratio = _contrast(palette.darkAccent, AppRawColors.charcoal);
      expect(palette.darkReady, ratio >= 4.0,
          reason: '${palette.name}: dark accent contrast is '
              '${ratio.toStringAsFixed(1)}:1');
    }
  });

  test('the default theme has a dark version, so the fallback works', () {
    expect(AppPalette.cerulean.darkReady, isTrue);
    for (final palette in AppPalette.all) {
      expect(palette.forDarkMode.darkReady, isTrue);
    }
  });

  test('light and dark themes carry their own set of color roles', () {
    for (final palette in AppPalette.all) {
      final light = AppTheme.light(palette);
      final dark = AppTheme.dark(palette);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<AppColorRoles>(), AppColorRoles.light);
      expect(dark.extension<AppColorRoles>(), AppColorRoles.dark);
    }
  });

  test('saved Light/Dark/Match phone names never change', () {
    // Renaming one would silently reset everyone's choice.
    expect(AppThemeMode.light.name, 'light');
    expect(AppThemeMode.dark.name, 'dark');
    expect(AppThemeMode.system.name, 'system');
    expect(AppThemeMode.byId(null), AppThemeMode.light);
    expect(AppThemeMode.byId('nonsense'), AppThemeMode.light);
  });
}
