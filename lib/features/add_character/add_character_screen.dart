import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/character_picker_dialog.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_picker_dialog.dart';
import '../../widgets/typed_character.dart';
import '../photos/photo_picking.dart';

/// Which face of the box is showing while adding a character. Mirrors the
/// character screen's Typed / Handwritten / Photos switcher (2026-09-21).
enum _AddView { typed, handwritten, photo }

/// Screen for creating a brand-new character. There is deliberately NO
/// handwriting-recognition/auto-suggestion step — the user always types or
/// pastes the character directly.
///
/// **One box, three faces** (2026-09-21), laid out like the character
/// screen: type the character, draw it, or attach a photo of it, switching
/// freely between them. Before this the drawing was the only way in and
/// was mandatory.
///
/// **What's required:** a definition, plus **at least one** of typed,
/// drawing or photo. Which one is up to you — a character seen on a menu
/// can start as a photo and be drawn later; one copied from a text can
/// start as typed. A tick on a button marks a face that has something in
/// it, so the requirement is visible without clicking through all three.
///
/// The definition stays required (decided 2026-09-20) so every card works
/// in Definition → Character flashcards.
///
/// Exactly one photo can be attached here. Photos are linked to several
/// characters, and characters to several photos, from the photo's own
/// screen — this is just the first one.
///
/// Tags, the photo and references can all be set here. None of them can be
/// *stored* until the character exists — a photo link and a reference both
/// need its id — so they're held in this screen's state and written
/// straight after [DictionaryStore.addCharacter] returns the saved entry.
/// Cancelling writes nothing at all: no half-made character, no stray photo
/// copied into the app's folder.
class AddCharacterScreen extends StatefulWidget {
  const AddCharacterScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<AddCharacterScreen> createState() => _AddCharacterScreenState();
}

class _AddCharacterScreenState extends State<AddCharacterScreen> {
  _AddView _view = _AddView.typed;

  final _typedController = TextEditingController();
  final _definitionController = TextEditingController();

  /// Chosen tags, in the order they were picked. Set through the tag
  /// picker rather than typed as one comma-separated string (2026-09-20),
  /// so existing tags get reused instead of near-duplicated.
  List<String> _tags = [];

  /// The one photo this character starts with. Still the picker's
  /// temporary file — the store copies it into the app's photos folder on
  /// save, so backing out leaves nothing behind.
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

  bool get _hasTyped => _typedController.text.trim().isNotEmpty;
  bool get _hasDrawing =>
      _capturedStrokes != null && _capturedStrokes!.isNotEmpty;
  bool get _hasPhoto => _photo != null;

  /// A definition, and at least one of the three faces.
  bool get _canSave =>
      _definitionController.text.trim().isNotEmpty &&
      (_hasTyped || _hasDrawing || _hasPhoto);

  bool _filled(_AddView view) => switch (view) {
        _AddView.typed => _hasTyped,
        _AddView.handwritten => _hasDrawing,
        _AddView.photo => _hasPhoto,
      };

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

  Future<void> _save() async {
    if (!_canSave) return;
    final now = DateTime.now(); // overwritten by addCharacter, but required here
    final draft = CharacterEntry(
      id: -1,
      // May be empty now that a drawing or a photo is enough on its own.
      // It is NOT defaulted to "?" any more (2026-09-21): that was
      // indistinguishable from someone typing a question mark. Everywhere
      // it's displayed uses TypedCharacterText, which shows a "missing"
      // icon instead.
      typedCharacter: _typedController.text.trim(),
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

  /// The selected face fills with the color theme, as on the character
  /// screen. A face with something in it also gets a tick, so "at least
  /// one of these" can be checked without opening all three.
  Widget _viewButton(_AddView view, String label) {
    final filled = _filled(view);
    return OutlinedButton(
      style: _view == view
          ? OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )
          : null,
      onPressed: () => setState(() => _view = view),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (filled) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle,
                size: 14, color: AppColors.success),
          ],
        ],
      ),
    );
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

  Widget _buildBox() {
    switch (_view) {
      case _AddView.typed:
        return Center(
          child: TextField(
            controller: _typedController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 72),
            maxLines: 1,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '字',
              hintStyle: TextStyle(fontSize: 72, color: AppColors.inactive),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      case _AddView.handwritten:
        return Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: HandwritingCanvas(
            readOnly: false,
            onStrokesChanged: (strokes) =>
                setState(() => _capturedStrokes = strokes),
          ),
        );
      case _AddView.photo:
        final photo = _photo;
        if (photo == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No photo yet'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add photo'),
              ),
            ],
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(photo, fit: BoxFit.contain),
        );
    }
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
            // A Wrap, so the third button drops to its own line rather than
            // overflowing on a narrow phone.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _viewButton(_AddView.typed, 'Typed'),
                _viewButton(_AddView.handwritten, 'Handwritten'),
                _viewButton(_AddView.photo, 'Photo'),
              ],
            ),
            const SizedBox(height: 8),
            if (!_hasTyped && !_hasDrawing && !_hasPhoto)
              Text(
                'Add at least one of these *',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            SizedBox(height: 240, child: _buildBox()),
            if (_view == _AddView.photo && _photo != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Replace'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _photo = null),
                    icon: const Icon(Icons.close),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _definitionController,
              decoration: const InputDecoration(
                labelText: 'Definition *',
                border: OutlineInputBorder(),
              ),
              // One line since 2026-09-20: Enter closes the keyboard instead
              // of adding a newline. It does NOT tap Save for you — the box
              // above may not be filled in, and Save is the one deliberate
              // commit for a new character.
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                            label: Text(typedCharacterLabel(c.typedCharacter)),
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
