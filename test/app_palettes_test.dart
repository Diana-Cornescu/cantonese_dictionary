import 'package:cantonese_dictionary_app/theme/app_colors.dart';
import 'package:cantonese_dictionary_app/theme/app_palettes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shortest distance between two hues on the color wheel, in degrees.
double _hueGap(Color a, Color b) {
  final d = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue).abs();
  return d > 180 ? 360 - d : d;
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
}
