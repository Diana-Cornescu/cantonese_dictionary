import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../widgets/clear_text_button.dart';
import '../../widgets/tag_name_dialog.dart';
import 'tag_detail_screen.dart';

/// Asks for a new tag's name and creates it, empty. Used by the + at the
/// top of the Tags screen (2026-09-25; the bottom bar's round + did this
/// while Tags was a tab, and a floating + before that). The new tag just
/// appears in the list — tap it to open it. It used to open straight away, but pushing a route in the same
/// frame the dialog pops is asking for trouble in the navigator's overlay
/// (2026-09-20).
Future<void> createTagFromDialog(
    BuildContext context, DictionaryStore store) async {
  final name = await promptForTagName(
    context,
    title: 'New tag',
    confirmLabel: 'Create',
    helperText: 'e.g. food, verb',
    validate: (value) {
      if (!isValidTagName(value)) {
        return "A tag can't be empty or contain a comma.";
      }
      if (store.allTags.contains(value)) return 'That tag already exists.';
      return null;
    },
  );
  if (name == null) return;
  await store.createTag(name);
}

/// Every tag, with how many characters carry it. Opened from Settings
/// since 2026-09-25 (it was a tab in the bottom bar before the Write tab
/// took its place). Search or scroll to find one, tap it to see (and
/// change) its characters, or use the + at the top to create an empty tag
/// and fill it afterwards.
///
/// No ⚙ here: this screen is opened from inside Settings.
///
/// Tags nobody carries are shown greyed with "0 characters" rather than
/// hidden: `replaceTags` keeps them on purpose, and seeing them is how you
/// notice a typo'd tag worth deleting. Added 2026-09-20.
class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final _search = TextEditingController();

  DictionaryStore get store => widget.store;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> _visibleTags() {
    final query = _search.text.trim().toLowerCase();
    final tags = store.allTags;
    if (query.isEmpty) return tags;
    return tags.where((t) => t.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tags = _visibleTags();
        final filtering = _search.text.trim().isNotEmpty;
        final disabledColor = Theme.of(context).disabledColor;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tags'),
            actions: [
              IconButton(
                tooltip: 'New tag',
                icon: const Icon(Icons.add),
                onPressed: () => createTagFromDialog(context, store),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search tags',
                    suffixIcon: clearTextButton(_search, () => setState(() {})),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: tags.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            filtering
                                ? 'No tags match.'
                                : 'No tags yet. Tap + above to make one, or add '
                                    'tags on a character.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: tags.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          final count = store.tagCount(tag);
                          final unused = count == 0;
                          return ListTile(
                            leading: Icon(
                              Icons.sell_outlined,
                              color: unused ? disabledColor : null,
                            ),
                            title: Text(
                              tag,
                              style: unused
                                  ? TextStyle(color: disabledColor)
                                  : null,
                            ),
                            subtitle: Text(
                              count == 1 ? '1 character' : '$count characters',
                              style: unused
                                  ? TextStyle(color: disabledColor)
                                  : null,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TagDetailScreen(store: store, tag: tag),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
