import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// How colors are organised (restructured 2026-09-25, before dark mode)
//
// **Every color value in the app is written down exactly once**, in one of
// two lists, both in this folder:
//   - [AppRawColors] below: every fixed color (whites, greys, black, the
//     red / gold / green that mean something, the photo overlays).
//   - `app_palettes.dart`: the 8 color themes you can pick in Settings.
//
// Screens and widgets never use either list directly. They ask for a color
// by what it's FOR, in one of three ways:
//   1. `Theme.of(context).colorScheme...` / the theme's text and icon
//      colors, for everything the theme already styles (buttons, text,
//      app bars, fields).
//   2. [AppColors] below: colors that MEAN something (⭐ gold, 🔥 red,
//      correct green) and are the same in every mode and every color theme.
//   3. `context.appColors` (see `app_color_roles.dart`): colors that depend
//      on light vs dark — inactive grey, the "on" filter look, box borders,
//      handwriting ink. Dark mode is then a second set of these roles, not
//      a hunt through every screen.
//
// `test/no_hardcoded_colors_test.dart` fails if any file outside
// `lib/theme/` writes a color value or uses [AppRawColors], so this can't
// quietly drift back.
// ---------------------------------------------------------------------------

/// The one list of fixed color values. **Only files in `lib/theme/` may use
/// these**; everything else goes through [AppColors], `context.appColors`
/// or the theme (see the note at the top of this file).
class AppRawColors {
  const AppRawColors._();

  // Neutrals.
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
  static const ironGrey = Color(0xFF474B48); // default text and icons
  static const midGrey = Color(0xFF9E9E9E); // box borders, faint labels
  static const silverGrey = Color(0xFFB4B8B5); // ironGrey, lightened
  static const paleGrey = Color(0xFFE6E9E7); // lighter again, for fills
  // Write-tab guide lines (2026-09-25). Always on the light "paper", so
  // one value works in both modes: visible on white and on offWhite.
  static const guideGrey = Color(0xFFD0D4D1);

  // Dark-mode neutrals (2026-09-25). Contrast against [charcoal] noted
  // where it matters; measured, not eyeballed.
  static const nearBlack = Color(0xFF121413); // text on a light accent
  static const charcoal = Color(0xFF1C1E1D); // dark background
  static const darkGrey = Color(0xFF2E3230); // "on" toggle fill
  static const dimGrey = Color(0xFF6A6F6C); // inactive, borders (3.3:1)
  static const ashGrey = Color(0xFF8A8F8C); // faint labels (5.1:1)
  static const lightGrey = Color(0xFFC4C8C5); // icons (9.9:1)
  static const offWhite = Color(0xFFE3E6E4); // text (13.3:1), paper
  static const white7 = Color(0x12FFFFFF); // dark photo placeholder

  // The three colors that mean something.
  static const seaGreen = Color(0xFF17843C);
  static const brickRed = Color(0xFFAC2220);
  static const darkGoldenrod = Color(0xFFAC8020);

  // Soft red fills for a hovered or pressed Delete button (2026-09-25):
  // brickRed mixed 70% toward white, and 70% toward charcoal. The same
  // mix as a color theme's own tint, so Delete matches the tag look.
  static const redTint = Color(0xFFE6BDBC); // nearBlack on it: 10.9:1
  static const redShade = Color(0xFF471F1E); // offWhite on it: 11.3:1

  // Translucent black, for laying over or standing in for a photo.
  static const black60 = Color(0x99000000); // caption strip over a photo
  static const black7 = Color(0x11000000); // a photo that hasn't loaded yet
}

/// Colors that **mean** something, applied explicitly at the call site and
/// never through the general theme, so a color theme can't swallow them
/// (see `docs/decisions/ui-conventions.md`, "Three colors mean something").
///
/// These are the same in every color theme. Colors that should change
/// between light and dark live in `context.appColors` instead.
class AppColors {
  const AppColors._();

  /// "Correct" answers, high accuracy, a filled-in face on Add character.
  static const success = AppRawColors.seaGreen;

  /// 🔥 hard, "incorrect" answers, delete and other destructive actions.
  static const danger = AppRawColors.brickRed;

  /// ⭐ favorite.
  static const star = AppRawColors.darkGoldenrod;

  /// Mid-range accuracy.
  static const warning = AppRawColors.darkGoldenrod;

  /// Text and icons on a solid fill of one of the colors above, or of a
  /// color theme (the Correct / Incorrect buttons, a theme swatch's tick).
  static const onAccent = AppRawColors.white;

  /// Nothing — for a border that should take up space without showing
  /// (an unselected theme swatch keeps its ring's width).
  static const none = AppRawColors.transparent;

  /// The dark strip behind the character names along the bottom of a
  /// photo in the gallery, and the text on it. Over a photo, so the same
  /// in light and dark.
  static const photoCaptionBackground = AppRawColors.black60;
  static const photoCaptionText = AppRawColors.white;
}
