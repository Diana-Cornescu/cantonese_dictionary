import 'package:flutter/material.dart';

/// Parses a comma-separated free-text tag string (as stored in
/// `CharacterEntry.tags`) into a [Wrap] of small rounded/pill-shaped tag
/// widgets (styled to match the app's rounded button look, e.g. the
/// Typed/Handwritten toggle on the character detail screen).
///
/// Tags are trimmed and empty segments are dropped; the string is not
/// otherwise normalized (no case-folding, no de-duplication), matching the
/// data model's deliberate choice to treat tags as free text rather than a
/// controlled vocabulary.
class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.tags});

  final String tags;

  /// Splits a raw comma-separated tag string into trimmed, non-empty tags.
  static List<String> parseTags(String raw) {
    return raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

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
          Container(
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
          ),
      ],
    );
  }
}
