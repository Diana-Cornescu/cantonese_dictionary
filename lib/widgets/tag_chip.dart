import 'package:flutter/material.dart';

import '../data/character_entry.dart' as model;

/// Parses a comma-separated free-text tag string (as stored in
/// `CharacterEntry.tags`) into a [Wrap] of small rounded/pill-shaped tag
/// widgets (styled to match the app's rounded button look, e.g. the
/// Typed/Handwritten toggle on the character detail screen).
///
/// Tags are trimmed, empty segments are dropped and exact duplicates are
/// removed (see `parseTags` in `data/character_entry.dart`, the single
/// shared parser also used when saving tags to the database).
///
/// With [onTagTap] set (2026-09-20) each chip becomes tappable — the
/// character detail screen uses it to open the tag's own screen, the same
/// way a photo's linked characters open theirs.
class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.tags, this.onTagTap});

  final String tags;

  /// Called with the tag name when a chip is tapped. Null (the default)
  /// leaves the chips as plain labels.
  final void Function(String tag)? onTagTap;

  /// Splits a raw comma-separated tag string into trimmed, non-empty tags.
  static List<String> parseTags(String raw) => model.parseTags(raw);

  @override
  Widget build(BuildContext context) {
    final parsed = parseTags(tags);
    if (parsed.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in parsed)
          _chip(context, colorScheme, tag),
      ],
    );
  }

  Widget _chip(BuildContext context, ColorScheme colorScheme, String tag) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(
        tag,
        style: TextStyle(color: colorScheme.onPrimaryContainer),
      ),
    );
    if (onTagTap == null) return body;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onTagTap!(tag),
      child: body,
    );
  }
}
