import 'package:flutter/material.dart';

/// A plain "edit this text" dialog. Resolves to the text as typed (not
/// trimmed — callers decide), or null if cancelled or dismissed.
///
/// A [StatefulWidget] so the controller belongs to the widget that uses it
/// and is disposed with it. Building the controller in the calling method
/// and disposing it after `await showDialog` returns looks right but is
/// too early: the route is still animating out, and any rebuild while it
/// does — and `main.dart` rebuilds the whole app on every store change —
/// makes the still-live TextField touch a disposed controller, which
/// throws "A TextEditingController was used after being disposed" and
/// takes the frame down with it. (2026-09-20.)
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  String initialValue = '',
  int maxLines = 5,
  String? hintText,
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      initialValue: initialValue,
      maxLines: maxLines,
      hintText: hintText,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initialValue,
    required this.maxLines,
    required this.hintText,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final int maxLines;
  final String? hintText;
  final String confirmLabel;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        decoration: widget.hintText == null
            ? null
            : InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
