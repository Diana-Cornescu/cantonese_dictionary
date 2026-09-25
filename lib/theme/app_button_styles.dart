import 'package:flutter/material.dart';

import 'app_color_roles.dart';
import 'app_colors.dart';

/// The app's outlined-button looks (2026-09-25), all built on the **tag
/// chip look**: a pill filled with a soft tint of the color theme, a thin
/// neutral outline, and text in a contrasting shade — near-black in light
/// mode, off-white in dark mode (see `widgets/tag_chip.dart`). The tint is
/// 30% of the theme color on the background in both modes, so light and
/// dark are mirror images of each other.
///
/// A button wears that look whenever it's **active**: hovered, pressed,
/// focused with the keyboard, or selected. At rest it's a plain outline in
/// the theme color, as before.
///
///  - [outlined]: every `OutlinedButton` in the app, via the theme. Nothing
///    to do at the call site.
///  - [selected]: a button that stays active because it's the chosen one —
///    the Typed / Handwritten / Photo(s) switchers.
///  - [danger]: Delete buttons. Red at rest; a soft red fill when active,
///    so they follow the same convention without losing their meaning.
///
/// The ⭐ Favorite / 🔥 Hard buttons keep their own fixed-grey flag look
/// (see "Two 'selected' looks" in `docs/decisions/ui-conventions.md`).
class AppButtonStyles {
  const AppButtonStyles._();

  /// The default for every outlined button; set in `AppTheme`.
  static ButtonStyle outlined(ColorScheme scheme) {
    Color foreground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) return _disabled(scheme);
      return _isActive(states) ? scheme.onPrimaryContainer : scheme.primary;
    }

    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(foreground),
      iconColor: WidgetStateProperty.resolveWith(foreground),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          !states.contains(WidgetState.disabled) && _isActive(states)
              ? scheme.primaryContainer
              : null),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: _disabledOutline(scheme));
        }
        return BorderSide(
            color: _isActive(states) ? scheme.outline : scheme.primary);
      }),
    );
  }

  /// Always in the active look: the chosen button of a switcher.
  static ButtonStyle selected(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(scheme.onPrimaryContainer),
      iconColor: WidgetStatePropertyAll(scheme.onPrimaryContainer),
      backgroundColor: WidgetStatePropertyAll(scheme.primaryContainer),
      side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
    );
  }

  /// A Delete button: red outline and text at rest; when active, a soft
  /// red fill with near-black (light) or off-white (dark) text.
  static ButtonStyle danger(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final roles = context.appColors;
    Color foreground(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) return _disabled(scheme);
      return _isActive(states) ? roles.onDangerFill : AppColors.danger;
    }

    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(foreground),
      iconColor: WidgetStateProperty.resolveWith(foreground),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          !states.contains(WidgetState.disabled) && _isActive(states)
              ? roles.dangerFill
              : null),
      side: WidgetStateProperty.resolveWith((states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? _disabledOutline(scheme)
              : AppColors.danger)),
    );
  }

  static bool _isActive(Set<WidgetState> states) =>
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.focused) ||
      states.contains(WidgetState.selected);

  // Material's own values for a disabled button.
  static Color _disabled(ColorScheme scheme) =>
      scheme.onSurface.withValues(alpha: 0.38);
  static Color _disabledOutline(ColorScheme scheme) =>
      scheme.onSurface.withValues(alpha: 0.12);
}
