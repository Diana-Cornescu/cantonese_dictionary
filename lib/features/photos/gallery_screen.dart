import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clear_text_button.dart';
import '../../widgets/list_filter_button.dart';
import '../../widgets/typed_character.dart';
import '../settings/settings_button.dart';
import 'photo_image.dart';
import 'photo_viewer_screen.dart';

/// Every photo, newest first unless the filter sheet says otherwise (the
/// choice is remembered): the Photos tab. Tap a photo to see it full size;
/// the bottom bar's round + adds a new one and asks which characters it
/// shows (see `addPhotoWithCharacters`).
///
/// Filters: a search box matching the linked characters' typed character,
/// definition or tags, or the photo's own note, plus one filter icon to its
/// right (1.6.0) whose sheet holds **favorites**, **hard** and
/// **unlinked**, the sort order and Clear filters. Same icon and sheet as
/// the home list's.
///
/// A photo has no star or hard flag of its own, so those two mean "linked
/// to at least one character that is". That makes them **mutually
/// exclusive with unlinked**, which the buttons enforce rather than leave
/// to you (2026-09-21): an unlinked photo has no characters to be starred,
/// so the combination could only ever show nothing. Turning on unlinked
/// also clears the search box, since "show me the loose ends" is a fresh
/// question rather than a narrowing of the last one.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _search = TextEditingController();

  /// Setting key for the remembered sort order (1.6.0).
  static const _sortSettingKey = 'photos_sort';

  static const _favorites = 'favorites';
  static const _hard = 'hard';
  static const _unlinked = 'unlinked';

  /// The "show only" toggles in the filter sheet (1.6.0; they were three
  /// separate buttons next to the search box from 1.4.0).
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
    // A broken link, with no color of its own: "unlinked" isn't one of
    // the app's three meaningful colors (red hard, gold favorite, green
    // correct).
    ListFilterOption(
      id: _unlinked,
      label: 'Unlinked',
      icon: Icons.link_off,
    ),
  ];

  /// The toggles reset each time the screen opens; the sort order is
  /// remembered in settings (and so travels with backups).
  late ListFilters _filters = ListFilters(
    sort: sortOrderFromSetting(widget.store.setting(_sortSettingKey)),
  );

  bool get _unlinkedOnly => _filters.isOn(_unlinked);
  bool get _starredOnly => _filters.isOn(_favorites);
  bool get _hardOnly => _filters.isOn(_hard);

  DictionaryStore get store => widget.store;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Whether any character linked to [photo] satisfies [test].
  bool _anyLinked(PhotoEntry photo, bool Function(CharacterEntry) test) {
    for (final c in store.characters) {
      if (photo.characterIds.contains(c.id) && test(c)) return true;
    }
    return false;
  }

  /// Applies what the filter sheet asked for, after enforcing the
  /// gallery's one rule. Returns what was actually applied, so the open
  /// sheet shows it.
  ///
  /// Unlinked is the odd one out: turning it on clears favorites, hard and
  /// the search box, so it always shows every loose photo. Turning
  /// favorites or hard on clears unlinked for the same reason — together
  /// they would guarantee an empty grid.
  ListFilters _applyFilters(ListFilters requested) {
    final on = {...requested.on};
    final unlinkedTurningOn =
        on.contains(_unlinked) && !_filters.isOn(_unlinked);
    if (unlinkedTurningOn) {
      on
        ..remove(_favorites)
        ..remove(_hard);
      // Outside setState: clear() notifies the search field's own listeners.
      _search.clear();
    } else if ((on.contains(_favorites) && !_filters.isOn(_favorites)) ||
        (on.contains(_hard) && !_filters.isOn(_hard))) {
      on.remove(_unlinked);
    }
    final applied = requested.copyWith(on: on);
    if (applied.sort != _filters.sort) {
      store.setSetting(_sortSettingKey, sortOrderSettingValue(applied.sort));
    }
    setState(() => _filters = applied);
    return applied;
  }

  List<PhotoEntry> _visiblePhotos() {
    final query = _search.text.trim().toLowerCase();
    final visible = store.photos.where((photo) {
      if (_unlinkedOnly && photo.characterIds.isNotEmpty) return false;
      if (_starredOnly && !_anyLinked(photo, (c) => c.isStarred)) return false;
      if (_hardOnly && !_anyLinked(photo, (c) => c.isHard)) return false;
      if (query.isEmpty) return true;
      if (photo.note.toLowerCase().contains(query)) return true;
      for (final c in store.characters) {
        if (!photo.characterIds.contains(c.id)) continue;
        if (c.typedCharacter.toLowerCase().contains(query) ||
            c.definition.toLowerCase().contains(query) ||
            c.tags.toLowerCase().contains(query)) {
          return true;
        }
      }
      return false;
    }).toList();
    // By date added, with the id breaking ties.
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
      listenable: store,
      builder: (context, _) {
        final photos = _visiblePhotos();
        final filtering =
            _filters.isFiltering || _search.text.trim().isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Photos'),
            actions: [SettingsButton(store: store)],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Search character, definition, tag, note',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              clearTextButton(_search, () => setState(() {})),
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
              Expanded(child: _buildGrid(photos, filtering)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<PhotoEntry> photos, bool filtering) {
    return photos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      filtering
                          ? 'No photos match.'
                          : 'No photos yet. Tap + below to add a photo of '
                              "characters you've seen out and about.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    // Characters separated by commas; a long list is cut off
                    // with "…" by the Text's ellipsis.
                    final label = [
                      for (final id in photo.characterIds)
                        ...store.characters
                            .where((c) => c.id == id)
                            .map((c) => typedCharacterLabel(c.typedCharacter)),
                    ].join(', ');
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerScreen(
                            store: store,
                            photoId: photo.id,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PhotoImage(store: store, photo: photo),
                            if (label.isNotEmpty)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  color: AppColors.photoCaptionBackground,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.photoCaptionText),
                                  ),
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
