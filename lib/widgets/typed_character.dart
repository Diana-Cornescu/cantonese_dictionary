import 'package:flutter/material.dart';

import '../theme/app_color_roles.dart';

/// Shows a character's typed text — or, when there isn't one, a grey
/// "missing" icon in its place.
///
/// Since 2026-09-21 a character can be created from a drawing or a photo
/// alone, so `CharacterEntry.typedCharacter` can legitimately be empty. It
/// used to be forced to `"?"` on save, which was indistinguishable from
/// someone deliberately typing a question mark, and said nothing about
/// *why* it was blank.
///
/// [style] sizes the text; the icon matches its font size unless
/// [iconSize] says otherwise.
class TypedCharacterText extends StatelessWidget {
  const TypedCharacterText({
    super.key,
    required this.text,
    this.style,
    this.iconSize,
  });

  final String text;
  final TextStyle? style;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isNotEmpty) return Text(text, style: style);
    return Icon(
      Icons.help_outline,
      size: iconSize ?? style?.fontSize ?? 24,
      color: context.appColors.inactive,
    );
  }
}

/// The same idea where only a string will do — a dialog's title, a
/// tooltip, a comma-separated list of names.
String typedCharacterLabel(String text) =>
    text.trim().isEmpty ? '(not typed)' : text;
