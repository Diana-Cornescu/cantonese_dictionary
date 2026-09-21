import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../widgets/character_picker_dialog.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_picker_dialog.dart';
import '../photos/photo_picking.dart';

/// Screen for creating a brand-new character: draw it, type it, define it.
/// There is deliberately NO handwriting-recognition/auto-suggestion step —
/// the user always types or pastes the character directly.
///
/// The handwritten sample is the only mandatory field (it's what makes the
/// row "a character" at all); the typed text is optional and defaults to
/// `"?"` if left blank, since the row-list screen uses the typed text as
/// its preview and needs something to show.
///
/// Tags, a photo and references can all be set here (2026-09-20). They
/// can't be *stored* until the character exists — a photo link and a
/// reference both need its id — so they're held in this screen's state and
/// written straight after [DictionaryStore.addCharacter] returns the saved
/// entry. Cancelling writes nothing at all: no half-made character, no
/// stray photo copied into the app's folder.
class AddCharacterScreen extends StatefulWidget {
  const AddCharacterScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<AddCharacterScreen> createState() => _AddCharacterScreenState();
}

class _AddCharacterScreenState extends State<AddCharacterScreen> {
  final _typedController = TextEditingController();
  final _definitionController = TextEditingController();

  /// Chosen tags, in the order they were picked. Set through the tag
  /// picker rather than typed as one comma-separated string (2026-09-20),
  /// so existing tags get reused instead of near-duplicated.
  List<String> _tags = [];

  /// A photo waiting to be attached. Still the picker's temporary file —
  /// the store copies it into the app's photos folder on save.
  File? _photo;

  /// Characters this one will reference. Written with [addReference] after
  /// the character has an id; references are symmetric, so each one also
  /// appears on the other character.
  final List<int> _referenceIds = [];

  List<List<StrokePoint>>? _capturedStrokes;

  DictionaryStore get store => widget.store;

  @override
  void dispose() {
    _typedController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  List<CharacterEntry> get _referenced => [
        for (final id in _referenceIds)
          ...store.characters.where((c) => c.id == id),
      ];

  Future<void> _editTags() async {
    final chosen = await pickTags(
      context,
      store,
      initial: _tags,
      title: 'Tags for this character',
    );
    if (chosen == null) return;
    setState(() => _tags = chosen);
  }

  Future<void> _pickPhoto() async {
    final file = await pickPhoto(context);
    if (file == null || !mounted) return;
    setState(() => _photo = file);
  }

  Future<void> _editReferences() async {
    final ids = await pickCharacters(
      context,
      store,
      initial: _referenceIds,
      title: 'Which characters does this one reference?',
    );
    if (ids == null) return;
    setState(() {
      _referenceIds
        ..clear()
        ..addAll(ids);
    });
  }

  /// A drawing and a definition are both required (definition required
  /// since 2026-09-20, so every card works in Definition -> Character
  /// flashcards).
  bool get _canSave =>
      _capturedStrokes != null &&
      _capturedStrokes!.isNotEmpty &&
      _definitionController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final now = DateTime.now(); // overwritten by addCharacter, but required here
    final typedText = _typedController.text.trim();
    final draft = CharacterEntry(
      id: -1,
      // Defaults to "?" rather than staying blank, since the row-list
      // screen previews entries by typed character.
      typedCharacter: typedText.isEmpty ? '?' : typedText,
      handwrittenSample: _capturedStrokes,
      definition: _definitionController.text.trim(),
      notes: '',
      tags: _tags.join(', '),
      isStarred: false,
      isHard: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      flashcardStats: FlashcardStats.zero,
      referencedCharacterIds: const [],
    );
    // Tapping Save is already the explicit, deliberate commit for a
    // brand-new row (unlike editing something that already exists), so no
    // extra confirmAction step is used here.
    final entry = await store.addCharacter(draft);
    // Both of these need the id the database just assigned, which is why
    // they happen here rather than as part of the draft.
    for (final id in _referenceIds) {
      await store.addReference(entry.id, id);
    }
    final photo = _photo;
    if (photo != null) {
      await store.addPhoto(photo, characterIds: [entry.id]);
    }
    if (mounted) Navigator.pop(context);
  }

  /// A section title with its action button on the right.
  Widget _sectionHeader(String title, Widget action) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        action,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add character'),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Draw the character *'),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey)),
                child: HandwritingCanvas(
                  readOnly: false,
                  onStrokesChanged: (strokes) =>
                      setState(() => _capturedStrokes = strokes),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typedController,
              decoration: const InputDecoration(
                labelText: 'Typed character (optional)',
                border: OutlineInputBorder(),
                helperText: 'Defaults to "?" if left blank',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _definitionController,
              decoration: const InputDecoration(
                labelText: 'Definition *',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              // Re-check whether Save can be enabled as you type.
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _sectionHeader(
              'Tags',
              TextButton.icon(
                onPressed: _editTags,
                icon: const Icon(Icons.add),
                label: const Text('Choose'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _tags.isEmpty
                  ? const Text('(no tags)')
                  : TagChips(tags: _tags.join(', ')),
            ),
            const SizedBox(height: 16),
            _sectionHeader(
              'Photo',
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photo == null ? 'Add' : 'Replace'),
              ),
            ),
            if (_photo == null)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('(no photo)'),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _photo!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _photo = null),
                    icon: const Icon(Icons.close),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _sectionHeader(
              'References',
              TextButton.icon(
                onPressed: _editReferences,
                icon: const Icon(Icons.add),
                label: const Text('Choose'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _referenceIds.isEmpty
                  ? const Text('(no references)')
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in _referenced)
                          Chip(
                            label: Text(c.typedCharacter),
                            onDeleted: () => setState(
                                () => _referenceIds.remove(c.id)),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
