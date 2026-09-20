import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../widgets/tag_name_dialog.dart';
import 'tag_detail_screen.dart';

/// Every tag, with how many characters carry it. Reached from the side
/// menu. Search or scroll to find one, tap it to see (and change) its
/// characters, or use + to create an empty tag and fill it afterwards.
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

  Future<void> _createTag() async {
    final name = await promptForTagName(
      context,
      title: 'New tag',
      initialValue: _search.text.trim(),
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
    // The new tag just appears in the list (createTag notifies, so the
    // ListenableBuilder redraws it) — tap it to open it. It used to open
    // straight away, but pushing a route in the same frame the dialog pops
    // is asking for trouble in the navigator's overlay (2026-09-20).
    await store.createTag(name);
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
                tooltip: 'Home',
                icon: const Icon(Icons.home_outlined),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'New tag',
            onPressed: _createTag,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search tags',
                    border: OutlineInputBorder(),
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
                                : 'No tags yet. Tap + to make one, or add '
                                    'tags on a character.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
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
