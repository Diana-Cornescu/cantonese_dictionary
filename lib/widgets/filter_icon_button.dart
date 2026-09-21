import 'package:flutter/material.dart';

/// One filter toggle for a list screen's search row.
///
/// Off, it's a plain outlined icon that sits quietly next to the search
/// box. On, it fills with the theme's container color, keeps a
/// primary-colored border and switches to [onIcon] in [activeColor] — three
/// signals at once, because "this list is being filtered" has to be
/// readable at a glance. A colour tint on its own reads as a hover state.
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

  /// Shown on hover/long-press. " (filtering)" is appended while [on].
  final String tooltip;

  final bool on;

  /// The glyph while filtering. Some icons have a filled variant for this
  /// (a filled star against an outlined one); others, like a broken link,
  /// have only the one shape, and [offIcon] can be left out.
  final IconData onIcon;

  /// The glyph while not filtering. Defaults to [onIcon].
  final IconData offIcon;

  /// The icon's color while filtering. Left null it uses the container's
  /// own foreground color, which is right for a filter with no meaning of
  /// its own; star and hard pass the colors those two flags always use.
  final Color? activeColor;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: on ? '$tooltip (filtering)' : tooltip,
        onPressed: onPressed,
        icon: Icon(
          on ? onIcon : offIcon,
          color: on ? (activeColor ?? colors.onPrimaryContainer) : null,
        ),
        style: IconButton.styleFrom(
          backgroundColor: on ? colors.primaryContainer : null,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: on ? colors.primary : colors.outline),
          ),
        ),
      ),
    );
  }
}
