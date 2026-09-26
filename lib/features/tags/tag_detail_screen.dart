import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_button_styles.dart';
import '../../widgets/character_picker_dialog.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/plus_minus_icon.dart';
import '../../widgets/tag_name_dialog.dart';
import '../../widgets/typed_character.dart';
import '../character_detail/character_detail_screen.dart';

/// One tag: every character carrying it, and the three things you can do
/// to the tag itself — add or remove characters in bulk, rename it
/// everywhere, or delete it.
///
/// Reached from the Tags screen and from a tag chip on a character's
/// screen. The tag name is held in state rather than read from the widget
/// so the screen keeps working after a rename.
class TagDetailScreen extends StatefulWidget {
  const TagDetailScreen({
    super.key,
    required this.store,
    required this.tag,
  });

  final DictionaryStore store;
  final String tag;

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  late String _tag = widget.tag;

  DictionaryStore get store => widget.store;

  /// Bulk add/remove, using the same checklist the photo screen uses for
  /// its linked characters.
  Future<void> _editCharacters(List<CharacterEntry> current) async {
    final ids = await pickCharacters(
      context,
      store,
      initial: [for (final c in current) c.id],
      title: 'Which characters have "$_tag"?',
    );
    if (ids == null) return;
    await store.setTagCharacters(_tag, ids);
  }

  Future<void> _rename() async {
    final newName = await promptForTagName(
      context,
      title: 'Rename tag',
      initialValue: _tag,
      confirmLabel: 'Rename',
      helperText: 'Renaming onto an existing tag merges the two.',
      validate: (value) => isValidTagName(value)
          ? null
          : "A tag can't be empty or contain a comma.",
    );
    if (newName == null || newName == _tag) return;

    if (store.allTags.contains(newName)) {
      if (!mounted) return;
      final confirmed = await confirmAction(
        context,
        title: 'Merge tags?',
        message: '"$newName" already exists. Every character tagged "$_tag" '
            'will be tagged "$newName" instead, and "$_tag" will be gone.',
        confirmLabel: 'Merge',
      );
      if (!confirmed) return;
    }
    final renamed = await store.renameTag(_tag, newName);
    if (renamed && mounted) setState(() => _tag = newName);
  }

  Future<void> _delete(int count) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete tag?',
      message: count == 0
          ? '"$_tag" will be removed from the tag list.'
          : '"$_tag" will be removed from $count '
              '${count == 1 ? 'character' : 'characters'}. '
              'The characters themselves are kept.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    await store.deleteTag(_tag);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final characters = store.charactersWithTag(_tag);
        return Scaffold(
          appBar: AppBar(
            title: Text(_tag),
            actions: [
              IconButton(
                tooltip: 'Rename tag',
                icon: const Icon(Icons.drive_file_rename_outline),
                onPressed: _rename,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    characters.isEmpty
                        ? 'No characters have this tag yet.'
                        : '${characters.length} '
                            '${characters.length == 1 ? 'character' : 'characters'}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: characters.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Use "Add or remove characters" below to put '
                              'some here.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: characters.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = characters[index];
                            return ListTile(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TypedCharacterText(
                                    text: entry.typedCharacter,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.isArchived
                                          ? '${entry.definition}  (archived)'
                                          : entry.definition,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CharacterDetailScreen(
                                    store: store,
                                    characterId: entry.id,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Same layout as the photo screen: the actions sit at the
                // bottom, well away from the app bar (2026-09-20).
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _editCharacters(characters),
                        // The same +/− as the photo screen (2026-09-26).
                        icon: const PlusMinusIcon(),
                        label: const Text('Add or remove characters'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _delete(characters.length),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete tag'),
                        style: AppButtonStyles.danger(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
