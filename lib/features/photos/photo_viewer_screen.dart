import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';
import '../../widgets/character_picker_dialog.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/typed_character.dart';
import '../../widgets/text_prompt_dialog.dart';
import '../character_detail/character_detail_screen.dart';
import 'photo_image.dart';

/// One photo, full size (pinch or scroll to zoom), with its date, note and
/// the characters it's linked to. From here you can edit the note, change
/// the linked characters (+ button), unlink it from every character, or
/// delete the photo. Tapping a linked character opens its screen; Back
/// returns here.
///
/// Unlink all and Delete live at the bottom of the screen, below the linked
/// characters, deliberately well away from the Home button in the app bar
/// (2026-09-20): deleting a photo used to be one mis-tap away from going
/// home.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({
    super.key,
    required this.store,
    required this.photoId,
  });

  final DictionaryStore store;
  final int photoId;

  PhotoEntry? _photo() {
    for (final p in store.photos) {
      if (p.id == photoId) return p;
    }
    return null;
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  Future<void> _editNote(BuildContext context, PhotoEntry photo) async {
    final newNote = await promptForText(
      context,
      title: 'Photo note',
      initialValue: photo.note,
      maxLines: 3,
      hintText: "e.g. where you saw it: 'menu at Tim Ho Wan'",
    );
    if (newNote == null) return;
    await store.updatePhotoNote(photo.id, newNote);
  }

  Future<void> _editCharacters(BuildContext context, PhotoEntry photo) async {
    final ids = await pickCharacters(context, store,
        initial: photo.characterIds);
    if (ids == null) return;
    await store.setPhotoCharacters(photo.id, ids);
  }

  /// Drops every character link but keeps the photo, which then shows up
  /// under the gallery's "Unlinked only" filter.
  Future<void> _unlinkAll(BuildContext context, PhotoEntry photo) async {
    final count = photo.characterIds.length;
    final confirmed = await confirmAction(
      context,
      title: 'Unlink photo?',
      message: count > 1
          ? 'This photo will be unlinked from all $count characters. '
              'The photo itself is kept.'
          : 'This photo will be unlinked from the character. '
              'The photo itself is kept.',
      confirmLabel: 'Unlink all',
    );
    if (!confirmed) return;
    await store.setPhotoCharacters(photo.id, const []);
  }

  Future<void> _delete(BuildContext context, PhotoEntry photo) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete photo?',
      message: photo.characterIds.length > 1
          ? 'This photo is linked to ${photo.characterIds.length} '
              'characters. It will be removed from all of them.'
          : 'This photo will be deleted.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    await store.deletePhoto(photo.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final photo = _photo();
        if (photo == null) {
          return const Scaffold(body: Center(child: Text('Photo removed.')));
        }
        final linked = [
          for (final id in photo.characterIds)
            ...store.characters.where((c) => c.id == id),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Photo'),
            actions: [
              IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home_outlined),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: PhotoImage(
                      store: store,
                      photo: photo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Added ${_formatDate(photo.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              photo.note.isEmpty ? '(no note)' : photo.note,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit note',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editNote(context, photo),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: linked.isEmpty
                                ? const Text('Not linked to any character')
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final c in linked)
                                        ActionChip(
                                          label: Text(typedCharacterLabel(
                                              c.typedCharacter)),
                                          tooltip: 'Open ${typedCharacterLabel(c.typedCharacter)}',
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CharacterDetailScreen(
                                                store: store,
                                                characterId: c.id,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                          IconButton(
                            tooltip: 'Add or remove characters',
                            icon: const Icon(Icons.add),
                            onPressed: () => _editCharacters(context, photo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: linked.isEmpty
                                  ? null
                                  : () => _unlinkAll(context, photo),
                              icon: const Icon(Icons.link_off),
                              label: const Text('Unlink all'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _delete(context, photo),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete photo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ],
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
