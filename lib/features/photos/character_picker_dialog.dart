import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';

/// A dialog listing every character with a checkbox, plus a search box.
/// Returns the chosen character ids, or null if cancelled. Used to choose
/// which characters a photo shows.
Future<List<int>?> pickCharacters(
  BuildContext context,
  DictionaryStore store, {
  List<int> initial = const [],
  String title = 'Which characters are in this photo?',
}) async {
  final selected = initial.toSet();
  final search = TextEditingController();
  final result = await showDialog<List<int>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final query = search.text.trim().toLowerCase();
        final characters = store.characters.where((c) {
          if (query.isEmpty) return true;
          return c.typedCharacter.toLowerCase().contains(query) ||
              c.definition.toLowerCase().contains(query);
        }).toList();
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 400,
            height: 420,
            child: Column(
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Search characters or definitions',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
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
                                value: selected.contains(c.id),
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
                                    selected.add(c.id);
                                  } else {
                                    selected.remove(c.id);
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, selected.toList()),
              child: Text('Save (${selected.length})'),
            ),
          ],
        );
      },
    ),
  );
  search.dispose();
  return result;
}
