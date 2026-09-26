/// Pieces shared by the two practice tabs, Flashcards and Write, so both
/// are laid out the same way (2026-09-26). Top to bottom:
///
///  1. the counter (and on Write the definition prompt),
///  2. the card / the writing box,
///  3. the card's language, name + emblem (`LanguageLine`),
///  4. [GoToCharacterLink],
///  5. empty space,
///  6. [PracticeActionBar]: the main buttons, pinned just above the bottom
///     navigation bar — Incorrect / Correct on Flashcards; Previous, Hide
///     X-ray and Next on Write.
///
/// 3 and 4 always take the same room whether or not they have anything to
/// show, so nothing jumps from one card to the next.
library;

import 'package:flutter/material.dart';

/// "Go to character screen", under the language line. When [visible] is
/// false it is hidden but still takes its space (Flashcards hides it until
/// the card is revealed, so it can't give the answer away).
class GoToCharacterLink extends StatelessWidget {
  const GoToCharacterLink({
    super.key,
    required this.onPressed,
    this.visible = true,
  });

  final VoidCallback onPressed;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: TextButton.icon(
        onPressed: visible ? onPressed : null,
        icon: const Icon(Icons.open_in_new),
        label: const Text('Go to character screen'),
      ),
    );
  }
}

/// The main action buttons, in one row along the bottom of the screen just
/// above the navigation bar, each taking an equal share of the width.
/// [placeholder] is shown instead, at the same height, when there are no
/// buttons to show yet (Flashcards before the card is flipped).
class PracticeActionBar extends StatelessWidget {
  const PracticeActionBar({
    super.key,
    required this.buttons,
    this.placeholder,
  });

  /// Height of the bar's content, so swapping buttons for the placeholder
  /// doesn't move anything.
  static const double height = 48;

  final List<Widget> buttons;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        height: height,
        child: buttons.isEmpty
            ? Center(child: placeholder)
            : Row(
                children: [
                  for (final (i, button) in buttons.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: button),
                  ],
                ],
              ),
      ),
    );
  }
}

/// A button label that shrinks to fit rather than wrapping or overflowing
/// when three buttons share a narrow phone's width.
class FittedLabel extends StatelessWidget {
  const FittedLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
  }
}
