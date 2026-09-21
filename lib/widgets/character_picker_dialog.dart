import 'package:flutter/material.dart';

import '../data/dictionary_store.dart';
import 'clear_text_button.dart';

/// A dialog listing every character with a checkbox, plus a search box.
/// Returns the chosen character ids, or null if cancelled.
///
/// Used to choose which characters a photo shows, and (2026-09-20) which
/// characters carry a tag — which is why it moved out of `features/photos`
/// into `widgets/`: two features share it now.
Future<List<int>?> pickCharacters(
  BuildContext context,
  DictionaryStore store, {
  List<int> initial = const [],
  String title = 'Which characters are in this photo?',
}) {
  return showDialog<List<int>>(
    context: context,
    builder: (_) => _CharacterPickerDialog(
      store: store,
      initial: initial,
      title: title,
    ),
  );
}

/// A [StatefulWidget] so the search controller is owned by the widget that
/// uses it and disposed with it — see the note in `tag_picker_dialog.dart`
/// for why disposing straight after `await showDialog` is too early.
class _CharacterPickerDialog extends StatefulWidget {
  const _CharacterPickerDialog({
    required this.store,
    required this.initial,
    required this.title,
  });

  final DictionaryStore store;
  final List<int> initial;
  final String title;

  @override
  State<_CharacterPickerDialog> createState() => _CharacterPickerDialogState();
}

class _CharacterPickerDialogState extends State<_CharacterPickerDialog> {
  final _search = TextEditingController();
  late final Set<int> _selected = widget.initial.toSet();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final characters = widget.store.characters.where((c) {
      if (query.isEmpty) return true;
      return c.typedCharacter.toLowerCase().contains(query) ||
          c.definition.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: 'Search characters or definitions',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: clearTextButton(_search, () => setState(() {})),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: characters.isEmpty
                  ? const Center(child: Text('No matching characters.'))
                  : ListView(
                      children: [
                        for (final c in characters)
                          CheckboxListTile(
                            dense: true,
                            value: _selected.contains(c.id),
                            title: Text(
                              c.isArchived
                                  ? '${c.typedCharacter}  (archived)'
                                  : c.typedCharacter,
                            ),
                            subtitle: Text(
                              c.definition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(c.id);
                              } else {
                                _selected.remove(c.id);
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
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: Text('Save (${_selected.length})'),
        ),
      ],
    );
  }
}
