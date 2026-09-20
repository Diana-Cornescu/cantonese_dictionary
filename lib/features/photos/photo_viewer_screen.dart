import 'package:flutter/material.dart';

import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';
import '../../widgets/confirm_dialog.dart';
import '../character_detail/character_detail_screen.dart';
import 'character_picker_dialog.dart';
import 'photo_image.dart';

/// One photo, full size (pinch or scroll to zoom), with its date, note and
/// the characters it's linked to. From here you can edit the note, change
/// the linked characters (+ button), or delete the photo. Tapping a linked
/// character opens its screen; Back returns here.
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
    final controller = TextEditingController(text: photo.note);
    final newNote = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Photo note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "e.g. where you saw it: 'menu at Tim Ho Wan'",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newNote == null) return;
    await store.updatePhotoNote(photo.id, newNote);
  }

  Future<void> _editCharacters(BuildContext context, PhotoEntry photo) async {
    final ids = await pickCharacters(context, store,
        initial: photo.characterIds);
    if (ids == null) return;
    await store.setPhotoCharacters(photo.id, ids);
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
                tooltip: 'Delete photo',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, photo),
              ),
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
                                          label: Text(c.typedCharacter),
                                          tooltip: 'Open ${c.typedCharacter}',
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
