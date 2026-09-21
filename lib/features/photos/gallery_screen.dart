import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';
import '../../theme/app_colors.dart';
import '../../widgets/character_picker_dialog.dart';
import '../../widgets/clear_text_button.dart';
import '../../widgets/filter_icon_button.dart';
import 'photo_image.dart';
import 'photo_picking.dart';
import 'photo_viewer_screen.dart';

/// Every photo, newest first, opened from the home screen. Tap a photo to
/// see it full size; the + button adds a new one and asks which characters
/// it shows.
///
/// Filters: a search box matching the linked characters' typed character,
/// definition or tags, or the photo's own note, plus three toggle buttons
/// to its right — **favorites**, **hard** and **unlinked** — in the same
/// style as the home list's (2026-09-21; the unlinked one was a labelled
/// chip and the other two are new).
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
  bool _unlinkedOnly = false;
  bool _starredOnly = false;
  bool _hardOnly = false;

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

  /// Unlinked is the odd one out: it clears the other two and the search
  /// box on the way on, so it always shows every loose photo.
  void _toggleUnlinked() {
    final turningOn = !_unlinkedOnly;
    // Outside setState: clear() notifies the search field's own listeners.
    if (turningOn) _search.clear();
    setState(() {
      _unlinkedOnly = turningOn;
      if (turningOn) {
        _starredOnly = false;
        _hardOnly = false;
      }
    });
  }

  /// Starred and hard turn unlinked off for the same reason — together they
  /// would guarantee an empty grid.
  void _toggleStarred() {
    setState(() {
      _starredOnly = !_starredOnly;
      if (_starredOnly) _unlinkedOnly = false;
    });
  }

  void _toggleHard() {
    setState(() {
      _hardOnly = !_hardOnly;
      if (_hardOnly) _unlinkedOnly = false;
    });
  }

  List<PhotoEntry> _visiblePhotos() {
    final query = _search.text.trim().toLowerCase();
    return store.photos.where((photo) {
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
  }

  Future<void> _addPhoto() async {
    final file = await pickPhoto(context);
    if (file == null || !mounted) return;
    final ids = await pickCharacters(context, store);
    if (ids == null) return; // cancelled: nothing is saved
    await store.addPhoto(file, characterIds: ids);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final photos = _visiblePhotos();
        final filtering = _unlinkedOnly ||
            _starredOnly ||
            _hardOnly ||
            _search.text.trim().isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Photos'),
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
            tooltip: 'Add photo',
            onPressed: _addPhoto,
            child: const Icon(Icons.add_a_photo_outlined),
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
                    FilterIconButton(
                      tooltip: 'Favorites only',
                      on: _starredOnly,
                      onIcon: Icons.star,
                      offIcon: Icons.star_border,
                      activeColor: AppColors.star,
                      onPressed: _toggleStarred,
                    ),
                    FilterIconButton(
                      tooltip: 'Hard only',
                      on: _hardOnly,
                      onIcon: Icons.local_fire_department,
                      offIcon: Icons.local_fire_department_outlined,
                      activeColor: AppColors.danger,
                      onPressed: _toggleHard,
                    ),
                    // A broken link, with no color of its own: "unlinked"
                    // isn't one of the app's three meaningful colors (red
                    // hard, gold favorite, green correct), so it leans on
                    // the filled background to show it's on.
                    FilterIconButton(
                      tooltip: 'Unlinked only',
                      on: _unlinkedOnly,
                      onIcon: Icons.link_off,
                      onPressed: _toggleUnlinked,
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
                          : 'No photos yet. Tap + to add a photo of '
                              "characters you've seen out and about.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
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
                            .map((c) => c.typedCharacter),
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
                                  color: const Color(0x99000000),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white),
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
