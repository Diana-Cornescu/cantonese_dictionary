import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One filter toggle for a list screen's search row.
///
/// Off: a light grey icon in a light grey outline, sitting quietly next to
/// the search box. On: the icon switches to [onIcon] in [activeColor] —
/// gold for favorites, red for hard — the outline goes **black** and the
/// button takes a **pale grey background**.
///
/// **Nothing here is theme-colored** (revised 2026-09-21). The first
/// version filled the background and border with the current palette while
/// filtering: loud, different in every color theme, and competing with the
/// gold and red that carry the actual meaning. The greys and the black are
/// fixed, so the only color in the button is the one that means something.
///
/// The character screen's toggle buttons wear the same three signals —
/// see `_toggleButtonStyle` there.
///
/// Shared by the home list and the photo gallery since 2026-09-21; it
/// started as a private helper on the home list a day earlier.
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    super.key,
    required this.tooltip,
    required this.on,
    required this.onIcon,
    required this.onPressed,
    IconData? offIcon,
    this.activeColor,
  }) : offIcon = offIcon ?? onIcon;

  /// Shown on hover/long-press. The same text whether or not it's on —
  /// the icon already says that — so two of these side by side describe
  /// themselves the same way.
  final String tooltip;

  final bool on;

  /// The glyph while filtering. Some icons have a filled variant for this
  /// (a filled star against an outlined one); others, like a broken link,
  /// have only the one shape, and [offIcon] can be left out.
  final IconData onIcon;

  /// The glyph while not filtering. Defaults to [onIcon].
  final IconData offIcon;

  /// The icon's color while filtering. Left null it darkens to the app's
  /// default icon grey, which is right for a filter with no color of its
  /// own (the gallery's "unlinked"); star and hard pass the gold and red
  /// those two flags always wear.
  final Color? activeColor;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          on ? onIcon : offIcon,
          color: on ? (activeColor ?? AppColors.ironGrey) : AppColors.inactive,
        ),
        style: IconButton.styleFrom(
          backgroundColor: on ? AppColors.selectedFill : null,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            side: BorderSide(
              color: on ? AppColors.selectedOutline : AppColors.inactive,
              width: on ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
