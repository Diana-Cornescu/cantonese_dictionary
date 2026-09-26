import 'package:flutter/material.dart';

import '../theme/app_color_roles.dart';
import '../theme/app_colors.dart';
import 'language_icon.dart';

/// The **Cantonese / Mandarin** pair for the optional Language field
/// (2026-09-26). Two independent toggles: one on marks the word as that
/// language, both on marks a word the two share, both off is "not set".
///
/// Shown as the first line of the Tags section on the Add character screen
/// and the character screen, above the real tags: a "special tag" that is
/// always offered, both buttons visible and grey when off. They wear
/// the same grey / black outline / pale fill look as the Favorite and Hard
/// buttons (see `_toggleButtonStyle` in the character screen and
/// `FilterIconButton`), without a meaning color of their own: a language
/// isn't good or bad, so it gets no gold or red.
///
/// Each carries a small emblem ([LanguageIcon], 2026-09-26): a bauhinia
/// for Cantonese, five stars for Mandarin. Black or white by mode when on,
/// grey when off, the same as the Favorite star and Hard flame.
class LanguageToggles extends StatelessWidget {
  const LanguageToggles({
    super.key,
    required this.isCantonese,
    required this.isMandarin,
    required this.onCantonese,
    required this.onMandarin,
    this.alignment = WrapAlignment.start,
  });

  final bool isCantonese;
  final bool isMandarin;
  final VoidCallback onCantonese;
  final VoidCallback onMandarin;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: 8,
      runSpacing: 8,
      children: [
        _toggle(context, 'Cantonese', LanguageEmblem.cantonese, isCantonese,
            onCantonese),
        _toggle(context, 'Mandarin', LanguageEmblem.mandarin, isMandarin,
            onMandarin),
      ],
    );
  }

  Widget _toggle(
    BuildContext context,
    String label,
    LanguageEmblem emblem,
    bool selected,
    VoidCallback onPressed,
  ) {
    final colors = context.appColors;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? colors.activeIcon : colors.inactive,
        iconColor: selected ? colors.activeIcon : colors.inactive,
        // Set even when off, so the app-wide hover tint doesn't reach
        // these: like the flags, they keep their greys.
        backgroundColor: selected ? colors.selectedFill : AppColors.none,
        side: BorderSide(
          color: selected ? colors.selectedOutline : colors.inactive,
          width: selected ? 1.5 : 1,
        ),
      ),
      onPressed: onPressed,
      // Takes the button's icon color (set by iconColor above) and size
      // from the IconTheme, like the star and flame do.
      icon: LanguageIcon(emblem),
      label: Text(label),
    );
  }
}
