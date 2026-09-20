import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';
import '../../widgets/character_picker_dialog.dart';
import 'photo_image.dart';
import 'photo_picking.dart';
import 'photo_viewer_screen.dart';

/// Every photo, newest first, opened from the home screen. Tap a photo to
/// see it full size; the + button adds a new one and asks which characters
/// it shows.
///
/// Filters (2026-09-20): an "Unlinked only" box (photos with no character,
/// e.g. to tidy up) and a search box matching the linked characters'
/// typed character, definition or tags, or the photo's own note.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _search = TextEditingController();
  bool _unlinkedOnly = false;

  DictionaryStore get store => widget.store;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PhotoEntry> _visiblePhotos() {
    final query = _search.text.trim().toLowerCase();
    return store.photos.where((photo) {
      if (_unlinkedOnly && photo.characterIds.isNotEmpty) return false;
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
        final filtering = _unlinkedOnly || _search.text.trim().isNotEmpty;
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
                        decoration: const InputDecoration(
                          hintText: 'Search character, definition, tag, note',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Unlinked only'),
                      selected: _unlinkedOnly,
                      onSelected: (on) => setState(() => _unlinkedOnly = on),
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
