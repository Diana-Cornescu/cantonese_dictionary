import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_picker_dialog.dart';

/// Screen for creating a brand-new character: draw it, type it, define it.
/// There is deliberately NO handwriting-recognition/auto-suggestion step —
/// the user always types or pastes the character directly.
///
/// The handwritten sample is the only mandatory field (it's what makes the
/// row "a character" at all); the typed text is optional and defaults to
/// `"?"` if left blank, since the row-list screen uses the typed text as
/// its preview and needs something to show.
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
  List<List<StrokePoint>>? _capturedStrokes;

  @override
  void dispose() {
    _typedController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  Future<void> _editTags() async {
    final chosen = await pickTags(
      context,
      widget.store,
      initial: _tags,
      title: 'Tags for this character',
    );
    if (chosen == null) return;
    setState(() => _tags = chosen);
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
    await widget.store.addCharacter(draft);
    if (mounted) Navigator.pop(context);
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _editTags,
                  icon: const Icon(Icons.add),
                  label: const Text('Choose tags'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _tags.isEmpty
                  ? const Text('(no tags)')
                  : TagChips(tags: _tags.join(', ')),
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
