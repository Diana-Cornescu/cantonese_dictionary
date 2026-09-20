import 'package:flutter/material.dart';

/// Asks for a tag name, with inline validation. Resolves to the trimmed
/// name, or null if cancelled or dismissed.
///
/// [validate] returns null when [value] is acceptable, or the message to
/// show under the field. It runs on Save and again whenever the text
/// changes clears a previous error.
///
/// This is a real [StatefulWidget] rather than a `showDialog` with a
/// controller made in the calling method, because a controller made that
/// way has nowhere correct to be disposed: disposing it right after
/// `await showDialog` returns is too early — the route is still animating
/// out, and any rebuild while it does (the whole app rebuilds on every
/// store change, see `main.dart`) makes the still-live TextField touch a
/// disposed controller. Owning it here ties its life to the widget that
/// uses it. (2026-09-20.)
Future<String?> promptForTagName(
  BuildContext context, {
  required String title,
  required String? Function(String value) validate,
  String initialValue = '',
  String confirmLabel = 'Save',
  String? helperText,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TagNameDialog(
      title: title,
      validate: validate,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      helperText: helperText,
    ),
  );
}

class _TagNameDialog extends StatefulWidget {
  const _TagNameDialog({
    required this.title,
    required this.validate,
    required this.initialValue,
    required this.confirmLabel,
    required this.helperText,
  });

  final String title;
  final String? Function(String value) validate;
  final String initialValue;
  final String confirmLabel;
  final String? helperText;

  @override
  State<_TagNameDialog> createState() => _TagNameDialogState();
}

class _TagNameDialogState extends State<_TagNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = widget.validate(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Tag name',
          border: const OutlineInputBorder(),
          errorText: _error,
          helperText: widget.helperText,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        // Enter saves, rather than doing nothing.
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
