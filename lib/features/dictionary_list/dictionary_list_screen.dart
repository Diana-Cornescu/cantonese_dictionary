import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clear_text_button.dart';
import '../../widgets/list_filter_button.dart';
import '../../widgets/typed_character.dart';
import '../character_detail/character_detail_screen.dart';
import '../settings/settings_button.dart';

/// The dictionary list screen, used both as the Characters tab's top
/// screen (active characters, with search and the filter icon) and — when
/// [isArchiveView] is true — as the "Archived characters" screen, opened
/// from Settings with its own back arrow.
///
/// Since 1.6.0 the other areas of the app are tabs in the bottom bar
/// (`features/shell/app_shell.dart`), and adding a character is the bar's
/// round + button. That replaced the ☰ side menu and the Add character bar
/// that was pinned under this list. The ⚙ top right opens Settings.
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

  /// Setting key for the remembered sort order (1.6.0). Shared by the home
  /// list and the archive, which are the same screen.
  static const _sortSettingKey = 'characters_sort';

  static const _favorites = 'favorites';
  static const _hard = 'hard';

  /// The "show only" toggles in the filter sheet (1.6.0; they were two
  /// separate buttons next to the search box from 1.4.0). Independent, not
  /// exclusive: with both on you get characters that are starred AND hard,
  /// and either one narrows further with whatever is typed in the box.
  static const _filterOptions = [
    ListFilterOption(
      id: _favorites,
      label: 'Favorites',
      icon: Icons.star,
      color: AppColors.star,
    ),
    ListFilterOption(
      id: _hard,
      label: 'Hard',
      icon: Icons.local_fire_department,
      color: AppColors.danger,
    ),
  ];

  /// The toggles reset each time the screen opens; the sort order is
  /// remembered in settings (and so travels with backups).
  late ListFilters _filters = ListFilters(
    sort: sortOrderFromSetting(widget.store.setting(_sortSettingKey)),
  );

  bool get _isFiltering =>
      _filters.isFiltering || _searchController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ListFilters _applyFilters(ListFilters requested) {
    if (requested.sort != _filters.sort) {
      widget.store
          .setSetting(_sortSettingKey, sortOrderSettingValue(requested.sort));
    }
    setState(() => _filters = requested);
    return requested;
  }

  List<CharacterEntry> _visibleCharacters() {
    final source = widget.isArchiveView
        ? widget.store.archivedCharacters
        : widget.store.activeCharacters;
    final query = _searchController.text.trim().toLowerCase();
    final starredOnly = _filters.isOn(_favorites);
    final hardOnly = _filters.isOn(_hard);
    final visible = source.where((c) {
      if (starredOnly && !c.isStarred) return false;
      if (hardOnly && !c.isHard) return false;
      if (query.isEmpty) return true;
      return c.typedCharacter.toLowerCase().contains(query) ||
          c.definition.toLowerCase().contains(query) ||
          c.tags.toLowerCase().contains(query);
    }).toList();
    // By date added, with the id breaking ties (two characters saved in
    // the same millisecond, or restored from a backup).
    visible.sort((a, b) {
      final byDate = a.createdAt.compareTo(b.createdAt);
      final oldestFirst = byDate != 0 ? byDate : a.id.compareTo(b.id);
      return _filters.sort == SortOrder.oldestFirst
          ? oldestFirst
          : -oldestFirst;
    });
    return visible;
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
            // The archive is opened from Settings, so it doesn't offer
            // Settings again; the tab's top screen does.
            actions: widget.isArchiveView
                ? null
                : [SettingsButton(store: widget.store)],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search characters, definitions, tags',
                          suffixIcon: clearTextButton(
                              _searchController, () => setState(() {})),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    ListFilterButton(
                      options: _filterOptions,
                      value: _filters,
                      onChanged: _applyFilters,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _isFiltering
                                ? 'No characters match.'
                                : widget.isArchiveView
                                    ? 'No archived characters.'
                                    : 'No characters yet.',
                            textAlign: TextAlign.center,
                          ),
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
                                TypedCharacterText(
                                  text: entry.typedCharacter,
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
                                  // Fire icon for "hard" (2026-09-20; was
                                  // "!"): filled red when on, outline when
                                  // off.
                                  icon: Icon(
                                    entry.isHard
                                        ? Icons.local_fire_department
                                        : Icons
                                            .local_fire_department_outlined,
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
        );
      },
    );
  }
}
