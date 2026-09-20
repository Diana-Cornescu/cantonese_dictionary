import 'package:flutter/material.dart';

import '../data/character_entry.dart';
import '../data/dictionary_store.dart';

/// A dialog for choosing a character's tags from the ones that already
/// exist, instead of retyping them and risking a near-miss ("food" vs
/// "Food"). Returns the chosen tag names, or null if cancelled.
///
/// The text box at the top does double duty: it filters the list, and when
/// what you typed isn't an existing tag it offers to create it. New tags
/// made this way are only written to the database when the character is
/// saved — cancelling here leaves nothing behind.
///
/// Added 2026-09-20 with the Tags screen. Before, tags were one free-text
/// comma-separated field on the Add and character screens.
Future<List<String>?> pickTags(
  BuildContext context,
  DictionaryStore store, {
  List<String> initial = const [],
  String title = 'Tags',
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _TagPickerDialog(
      store: store,
      initial: initial,
      title: title,
    ),
  );
}

/// A [StatefulWidget] so the search controller is owned by the widget that
/// uses it and disposed with it. Disposing a controller straight after
/// `await showDialog` returns is too early: the route is still animating
/// out and can rebuild, which throws "A TextEditingController was used
/// after being disposed". (2026-09-20.)
class _TagPickerDialog extends StatefulWidget {
  const _TagPickerDialog({
    required this.store,
    required this.initial,
    required this.title,
  });

  final DictionaryStore store;
  final List<String> initial;
  final String title;

  @override
  State<_TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<_TagPickerDialog> {
  final _search = TextEditingController();
  late final List<String> _selected = [...widget.initial];

  DictionaryStore get store => widget.store;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _create(String name) {
    // Clearing the box notifies the TextField, so it happens outside
    // setState rather than inside the callback.
    _search.clear();
    setState(() {
      if (!_selected.contains(name)) _selected.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final typed = _search.text.trim();
    final query = typed.toLowerCase();
    // Everything known, plus anything picked in this dialog that isn't
    // saved yet, so a tag you just created stays visible and ticked.
    final known = <String>[
      ...store.allTags,
      for (final tag in _selected)
        if (!store.allTags.contains(tag)) tag,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final shown = query.isEmpty
        ? known
        : known.where((t) => t.toLowerCase().contains(query)).toList();
    final canCreate = isValidTagName(typed) && !known.contains(typed);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search or type a new tag',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (canCreate) _create(typed);
              },
            ),
            if (typed.contains(','))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "A tag can't contain a comma — add them one at a time.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (canCreate)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add),
                      title: Text('Create "$typed"'),
                      onTap: () => _create(typed),
                    ),
                  if (shown.isEmpty && !canCreate)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No tags yet. Type one above.'),
                    ),
                  for (final tag in shown)
                    CheckboxListTile(
                      dense: true,
                      value: _selected.contains(tag),
                      title: Text(tag),
                      subtitle: Text(
                        store.tagCount(tag) == 1
                            ? '1 character'
                            : '${store.tagCount(tag)} characters',
                      ),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          if (!_selected.contains(tag)) _selected.add(tag);
                        } else {
                          _selected.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, [..._selected]),
          child: Text('Save (${_selected.length})'),
        ),
      ],
    );
  }
}
