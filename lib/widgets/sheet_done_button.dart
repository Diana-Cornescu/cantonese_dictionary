import 'package:flutter/material.dart';

/// A full-width **Done** button at the bottom of a bottom sheet, which just
/// closes it (2026-09-26). Outlined with a ✓, the same style as the
/// character screen's Archive button, so it reads as a quiet way out
/// rather than a big "commit" action. Choices in these sheets apply as soon as
/// they're tapped, so Done saves nothing; it's there so there's an obvious
/// way out besides tapping outside the sheet or swiping it down.
///
/// Used by the filter sheet (home list, Archive, Photos) under Clear
/// filters, and at the bottom of the Flashcards and Write … panels.
/// [context] must be the sheet's own context, so it's the sheet that
/// closes.
class SheetDoneButton extends StatelessWidget {
  const SheetDoneButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.check),
        label: const Text('Done'),
      ),
    );
  }
}
