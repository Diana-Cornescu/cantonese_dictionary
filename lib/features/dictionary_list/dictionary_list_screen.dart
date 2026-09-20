import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';
import '../add_character/add_character_screen.dart';
import '../character_detail/character_detail_screen.dart';
import '../flashcards/flashcard_mode_screen.dart';
import '../photos/gallery_screen.dart';
import '../settings/settings_screen.dart';

/// The dictionary list screen, used both as the app's home/row-view screen
/// (active characters, with search, and entry points into flashcard mode,
/// photos, settings (backup & restore), adding a new character, and the
/// archive) and — when
/// [isArchiveView] is true — as a pushed "Archived characters" screen with
/// its own back arrow and title, reached via the archive icon rather than
/// an in-place toggle.
class DictionaryListScreen extends StatefulWidget {
  const DictionaryListScreen({
    super.key,
    required this.store,
    this.isArchiveView = false,
  });

  final DictionaryStore store;
  final bool isArchiveView;

  @override
  State<DictionaryListScreen> createState() => _DictionaryListScreenState();
}

class _DictionaryListScreenState extends State<DictionaryListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CharacterEntry> _visibleCharacters() {
    final source = widget.isArchiveView
        ? widget.store.archivedCharacters
        : widget.store.activeCharacters;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source.where((c) {
      return c.typedCharacter.toLowerCase().contains(query) ||
          c.definition.toLowerCase().contains(query) ||
          c.tags.toLowerCase().contains(query);
    }).toList();
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final entries = _visibleCharacters();
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isArchiveView
                ? 'Archived characters'
                : 'Cantonese Dictionary'),
            actions: widget.isArchiveView
                ? [
                    IconButton(
                      tooltip: 'Home',
                      icon: const Icon(Icons.home_outlined),
                      onPressed: _goHome,
                    ),
                  ]
                : [
                    IconButton(
                      tooltip: 'View archived',
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DictionaryListScreen(
                            store: widget.store,
                            isArchiveView: true,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Flashcard mode',
                      // Rotated 90° clockwise per feedback on the icon's
                      // orientation.
                      icon: const RotatedBox(
                        quarterTurns: 1,
                        child: Icon(Icons.style_outlined),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FlashcardModeScreen(store: widget.store),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Photos',
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GalleryScreen(store: widget.store),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(store: widget.store),
                        ),
                      ),
                    ),
                  ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search characters, definitions, tags',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          widget.isArchiveView
                              ? 'No archived characters.'
                              : 'No characters match.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CharacterDetailScreen(
                                  store: widget.store,
                                  characterId: entry.id,
                                ),
                              ),
                            ),
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.typedCharacter,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.definition,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Star and hard-flag are the app's only two
                                // instant, no-confirmation actions — both are
                                // trivially reversible with one more tap.
                                // Archive/delete now live in the character
                                // detail screen, so only these two remain
                                // here, with tight spacing between them.
                                IconButton(
                                  tooltip: 'Star',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    entry.isStarred
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: entry.isStarred
                                        ? AppColors.star
                                        : null,
                                  ),
                                  onPressed: () =>
                                      widget.store.toggleStarred(entry.id),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Hard',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    Icons.priority_high,
                                    color:
                                        entry.isHard ? AppColors.danger : null,
                                  ),
                                  onPressed: () =>
                                      widget.store.toggleHard(entry.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: widget.isArchiveView
              ? null
              : FloatingActionButton(
                  tooltip: 'Add character',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCharacterScreen(store: widget.store),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}
