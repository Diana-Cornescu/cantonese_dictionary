import 'package:flutter/material.dart';

/// Central palette. Every other file references these named colors —
/// never raw hex literals — so the whole app stays in sync with the one
/// approved palette.
///
/// Usage across the app:
///   - White background, blue tones (cerulean/cobaltBlue/tropicalTeal) for
///     buttons, selected states, and hover — everywhere.
///   - ironGrey for default icons and text, silverGrey for an off/inactive
///     one (a filter button that isn't filtering).
///   - Semantic highlight colors (star, success/"correct", danger/
///     "incorrect"/destructive) are red/gold/green, applied explicitly at
///     the call site rather than through the general theme.
class AppColors {
  const AppColors._();

  static const seaGreen = Color(0xFF17843C);
  static const brickRed = Color(0xFFAC2220);
  static const darkGoldenrod = Color(0xFFAC8020);
  static const ironGrey = Color(0xFF474B48);
  static const silverGrey = Color(0xFFB4B8B5); // ironGrey, lightened
  static const paleGrey = Color(0xFFE6E9E7); // lighter again, for fills
  static const honeydew = Color(0xFFCDE2D1);
  static const tropicalTeal = Color(0xFF20AAAC);
  static const cerulean = Color(0xFF207BAC);
  static const cobaltBlue = Color(0xFF204CAC);

  // Semantic aliases used at call sites throughout the app.
  static const success = seaGreen; // "correct" answers, high accuracy
  static const danger = brickRed; // "incorrect" answers, delete/destructive
  static const star = darkGoldenrod; // active star/favorite
  static const warning = darkGoldenrod; // mid-range accuracy
  static const inactive = silverGrey; // filter buttons that aren't filtering
  static const selectedOutline = Color(0xFF000000); // a selected toggle
  static const selectedFill = paleGrey; // ...and its background
}
