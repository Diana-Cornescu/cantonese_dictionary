import 'package:flutter/material.dart';

/// Shows a simple Cancel/Confirm [AlertDialog] and resolves to `true` only
/// if the user taps the confirm button. Dismissing any other way (system
/// back gesture, tapping outside, or tapping Cancel) resolves to `false`.
///
/// Intended for destructive actions (e.g. deleting a character) where
/// Phase 2 screens want a single `await confirmAction(...)` guard before
/// calling into `DictionaryStore`.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
