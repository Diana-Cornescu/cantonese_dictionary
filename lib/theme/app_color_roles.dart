import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colors the standard Material theme has no slot for and that will need
/// a different value in dark mode. Registered on the theme as a
/// [ThemeExtension], and read on screens with `context.appColors` (see
/// [AppColorRolesContext]), e.g. `context.appColors.inactive`.
///
/// Each role is named for what it's FOR, not what it looks like, so a
/// screen never needs to know which grey it's getting. The values live in
/// [AppColorRoles.light] and [AppColorRoles.dark]; the theme picks one.
///
/// Part of the 2026-09-25 color restructure — see the note at the top of
/// `app_colors.dart`.
@immutable
class AppColorRoles extends ThemeExtension<AppColorRoles> {
  const AppColorRoles({
    required this.inactive,
    required this.activeIcon,
    required this.selectedOutline,
    required this.selectedFill,
    required this.frame,
    required this.faintText,
    required this.ink,
    required this.paper,
    required this.onPaper,
    required this.photoPlaceholder,
    required this.dangerFill,
    required this.onDangerFill,
    required this.referenceInk,
    required this.writingGuide,
  });

  /// Something switched off or not filled in yet: an off filter or flag
  /// (icon and outline), a hint like the 字 on Add character, the grey
  /// "missing" icon for an untyped character, the "Added" date.
  final Color inactive;

  /// A switched-on toggle's icon or label when it has no meaning color of
  /// its own (the gallery's 🔗 unlinked filter, the Favorite / Hard labels).
  final Color activeIcon;

  /// A switched-on toggle's outline…
  final Color selectedOutline;

  /// …and its background. See "Two 'selected' looks" in
  /// `docs/decisions/ui-conventions.md`.
  final Color selectedFill;

  /// The thin border around a drawing box and a flashcard.
  final Color frame;

  /// Small, deliberately quiet text, like the "Character → Definition"
  /// label on a flashcard.
  final Color faintText;

  /// Handwriting strokes.
  final Color ink;

  /// Behind a handwriting box. See-through in light mode (the white page
  /// shows, as it always has); a light sheet in dark mode, so black ink
  /// stays readable and your drawing looks the same in both (decided
  /// 2026-09-25).
  final Color paper;

  /// Icons drawn on [paper]: the undo / clear buttons in a drawing box.
  final Color onPaper;

  /// Stands in for a photo while its file loads.
  final Color photoPlaceholder;

  /// A Delete button's background while hovered, pressed or focused — the
  /// red version of a tag chip's tint (see `app_button_styles.dart`)…
  final Color dangerFill;

  /// …and its text and icon then: near-black in light mode, off-white in
  /// dark mode — the same as the tag look.
  final Color onDangerFill;

  /// The correct form of a character, filled in under your ink on the
  /// Write tab once you tap Check. Drawn on [paper], so it's the same in
  /// both modes.
  final Color referenceInk;

  /// The faint 米字格 guide lines in a Write-tab box, also on [paper].
  final Color writingGuide;

  /// Light mode — everything the app looked like before dark mode.
  static const light = AppColorRoles(
    inactive: AppRawColors.silverGrey,
    activeIcon: AppRawColors.ironGrey,
    selectedOutline: AppRawColors.black,
    selectedFill: AppRawColors.paleGrey,
    frame: AppRawColors.midGrey,
    faintText: AppRawColors.midGrey,
    ink: AppRawColors.black,
    paper: AppRawColors.transparent,
    onPaper: AppRawColors.ironGrey,
    photoPlaceholder: AppRawColors.black7,
    dangerFill: AppRawColors.redTint,
    onDangerFill: AppRawColors.nearBlack,
    referenceInk: AppRawColors.silverGrey,
    writingGuide: AppRawColors.guideGrey,
  );

  /// Dark mode (2026-09-25). Same roles, lighter greys: icons and the "on"
  /// look use light greys instead of dark ones, and the handwriting box
  /// stays a light sheet with black ink.
  static const dark = AppColorRoles(
    inactive: AppRawColors.dimGrey,
    activeIcon: AppRawColors.lightGrey,
    selectedOutline: AppRawColors.offWhite,
    selectedFill: AppRawColors.darkGrey,
    frame: AppRawColors.dimGrey,
    faintText: AppRawColors.ashGrey,
    ink: AppRawColors.black,
    paper: AppRawColors.offWhite,
    onPaper: AppRawColors.ironGrey,
    photoPlaceholder: AppRawColors.white7,
    dangerFill: AppRawColors.redShade,
    onDangerFill: AppRawColors.offWhite,
    referenceInk: AppRawColors.silverGrey,
    writingGuide: AppRawColors.guideGrey,
  );

  @override
  AppColorRoles copyWith({
    Color? inactive,
    Color? activeIcon,
    Color? selectedOutline,
    Color? selectedFill,
    Color? frame,
    Color? faintText,
    Color? ink,
    Color? paper,
    Color? onPaper,
    Color? photoPlaceholder,
    Color? dangerFill,
    Color? onDangerFill,
    Color? referenceInk,
    Color? writingGuide,
  }) {
    return AppColorRoles(
      inactive: inactive ?? this.inactive,
      activeIcon: activeIcon ?? this.activeIcon,
      selectedOutline: selectedOutline ?? this.selectedOutline,
      selectedFill: selectedFill ?? this.selectedFill,
      frame: frame ?? this.frame,
      faintText: faintText ?? this.faintText,
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      onPaper: onPaper ?? this.onPaper,
      photoPlaceholder: photoPlaceholder ?? this.photoPlaceholder,
      dangerFill: dangerFill ?? this.dangerFill,
      onDangerFill: onDangerFill ?? this.onDangerFill,
      referenceInk: referenceInk ?? this.referenceInk,
      writingGuide: writingGuide ?? this.writingGuide,
    );
  }

  /// Blends between two sets, used by Flutter when the theme animates
  /// (e.g. switching between light and dark).
  @override
  AppColorRoles lerp(ThemeExtension<AppColorRoles>? other, double t) {
    if (other is! AppColorRoles) return this;
    return AppColorRoles(
      inactive: Color.lerp(inactive, other.inactive, t)!,
      activeIcon: Color.lerp(activeIcon, other.activeIcon, t)!,
      selectedOutline: Color.lerp(selectedOutline, other.selectedOutline, t)!,
      selectedFill: Color.lerp(selectedFill, other.selectedFill, t)!,
      frame: Color.lerp(frame, other.frame, t)!,
      faintText: Color.lerp(faintText, other.faintText, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      onPaper: Color.lerp(onPaper, other.onPaper, t)!,
      photoPlaceholder:
          Color.lerp(photoPlaceholder, other.photoPlaceholder, t)!,
      dangerFill: Color.lerp(dangerFill, other.dangerFill, t)!,
      onDangerFill: Color.lerp(onDangerFill, other.onDangerFill, t)!,
      referenceInk: Color.lerp(referenceInk, other.referenceInk, t)!,
      writingGuide: Color.lerp(writingGuide, other.writingGuide, t)!,
    );
  }
}

/// `context.appColors.inactive` instead of
/// `Theme.of(context).extension<AppColorRoles>()!.inactive`.
extension AppColorRolesContext on BuildContext {
  /// Falls back to [AppColorRoles.light] if a theme somehow lacks the
  /// extension (e.g. a test that builds its own bare `MaterialApp`), rather
  /// than crashing.
  AppColorRoles get appColors =>
      Theme.of(this).extension<AppColorRoles>() ?? AppColorRoles.light;
}
