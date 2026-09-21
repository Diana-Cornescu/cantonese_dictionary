import 'package:flutter/material.dart';

/// The **✕** that clears a search box, for a text field's `suffixIcon`.
///
/// Returns null while [controller] is empty, so the ✕ only appears once
/// there's something to clear — a permanent one is a permanently dead
/// button. That means the field has to be rebuilt as you type, which every
/// search box here already does through its `onChanged`.
///
/// [onCleared] is the caller's `setState`: clearing has to repaint both the
/// field (the ✕ goes away) and whatever the text was filtering.
///
/// Sized down from the default 48 px tap target, which would otherwise
/// stretch a `isDense: true` field taller than the buttons beside it.
///
/// Added 2026-09-21.
Widget? clearTextButton(
  TextEditingController controller,
  VoidCallback onCleared, {
  String tooltip = 'Clear',
}) {
  if (controller.text.isEmpty) return null;
  return IconButton(
    tooltip: tooltip,
    icon: const Icon(Icons.clear),
    iconSize: 20,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    // clear() notifies the field's own listeners, so it runs outside the
    // caller's setState rather than inside its callback.
    onPressed: () {
      controller.clear();
      onCleared();
    },
  );
}
