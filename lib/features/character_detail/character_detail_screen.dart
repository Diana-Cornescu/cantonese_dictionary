import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/tag_chip.dart';
import '../photos/photo_image.dart';
import '../photos/photo_picking.dart';
import '../photos/photo_viewer_screen.dart';

/// Detail screen for one character: a character window (typed/handwritten
/// toggle) and a translation window (definition, flashcard stats, notes,
/// tags, references, photos), side by side on wide screens or stacked on narrow
/// ones — a responsive breakpoint stands in for a custom draggable divider,
/// which was explicitly deferred to a later version. Archive/delete for
/// this character live at the very bottom of the screen.
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({
    super.key,
    required this.store,
    required this.characterId,
  });

  final DictionaryStore store;
  final int characterId;

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  bool _showHandwritten = false;
  final _referenceSearchController = TextEditingController();

  @override
  void dispose() {
    _referenceSearchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<String?> _promptForText(String title, String initialValue) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, maxLines: 5, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTypedCharacter(CharacterEntry entry) async {
    final newValue = await _promptForText('Edit character', entry.typedCharacter);
    if (newValue == null) return;
    final trimmed = newValue.trim();
    // Same "?" fallback as the add-character screen: the typed text is the
    // row-list preview, so it's never allowed to end up blank.
    final finalValue = trimmed.isEmpty ? '?' : trimmed;
    final confirmed = await confirmAction(
      context,
      title: 'Save character?',
      message: "Save changes to the typed character for '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store
          .updateCharacter(entry.copyWith(typedCharacter: finalValue));
    }
  }

  Future<void> _editDefinition(CharacterEntry entry) async {
    final newValue = await _promptForText('Edit definition', entry.definition);
    if (newValue == null) return;
    // A definition is required (2026-09-20), so it can't be emptied.
    if (newValue.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("The definition can't be empty.")));
      }
      return;
    }
    if (!mounted) return;
    final confirmed = await confirmAction(
      context,
      title: 'Save definition?',
      message: "Save changes to the definition for '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store
          .updateCharacter(entry.copyWith(definition: newValue.trim()));
    }
  }

  Future<void> _editNotes(CharacterEntry entry) async {
    final newValue = await _promptForText('Edit notes', entry.notes);
    if (newValue == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Save notes?',
      message: "Save changes to the notes for '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store.updateCharacter(entry.copyWith(notes: newValue));
    }
  }

  Future<void> _editTags(CharacterEntry entry) async {
    final newValue = await _promptForText('Edit tags', entry.tags);
    if (newValue == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Save tags?',
      message: "Save changes to the tags for '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store.updateCharacter(entry.copyWith(tags: newValue));
    }
  }

  Future<void> _redrawHandwriting(CharacterEntry entry) async {
    List<List<StrokePoint>>? captured;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Draw the character'),
        content: SizedBox(
          width: 280,
          height: 280,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: HandwritingCanvas(
              readOnly: false,
              onStrokesChanged: (strokes) => captured = strokes,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Use this drawing'),
          ),
        ],
      ),
    );
    // An emptied (cleared) drawing is treated like Cancel: the saved
    // drawing is only ever replaced by a real one.
    if (saved != true || captured == null || captured!.isEmpty) return;
    final confirmed = await confirmAction(
      context,
      title: 'Save handwriting?',
      message: "Overwrite the saved handwriting for '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store
          .updateCharacter(entry.copyWith(handwrittenSample: captured));
    }
  }

  Future<void> _removeReference(
      CharacterEntry entry, int otherId, String otherTyped) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove reference?',
      message:
          "Remove the link between '${entry.typedCharacter}' and '$otherTyped'?",
    );
    if (confirmed) {
      await widget.store.removeReference(entry.id, otherId);
    }
  }

  Future<void> _handleArchiveToggle(CharacterEntry entry) async {
    final verb = entry.isArchived ? 'Unarchive' : 'Archive';
    final confirmed = await confirmAction(
      context,
      title: '$verb character?',
      message: "$verb '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store.toggleArchived(entry.id);
    }
  }

  Future<void> _handleDelete(CharacterEntry entry) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete character?',
      message: "Delete '${entry.typedCharacter}'? This cannot be undone.",
    );
    if (confirmed) {
      await widget.store.deleteCharacter(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        CharacterEntry? entry;
        for (final c in widget.store.characters) {
          if (c.id == widget.characterId) {
            entry = c;
            break;
          }
        }
        if (entry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return const Scaffold(
              body: Center(child: Text('Character removed.')));
        }
        final current = entry;
        return Scaffold(
          appBar: AppBar(
            title: Text(current.typedCharacter),
            actions: [
              IconButton(
                tooltip: 'Home',
                icon: const Icon(Icons.home_outlined),
                onPressed: _goHome,
              ),
            ],
          ),
          // SafeArea (rather than a fixed bottom padding number) insets the
          // scrollable content by whatever the current device's system UI
          // actually needs — a 3-button nav bar, a gesture-navigation
          // indicator, or none at all on desktop/web — so the archive/
          // delete row at the very bottom never ends up hidden behind it.
          // `top: false` because the AppBar already accounts for the status
          // bar/notch; without that this would double-pad the top.
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final characterWindow = _buildCharacterWindow(current);
                  final translationWindow = _buildTranslationWindow(current);
                  final bottomActions = _buildBottomActions(current);
                  if (constraints.maxWidth >= 600) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: characterWindow),
                            Expanded(child: translationWindow),
                          ],
                        ),
                        bottomActions,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      characterWindow,
                      translationWindow,
                      bottomActions,
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  ButtonStyle _selectedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildCharacterWindow(CharacterEntry entry) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: _showHandwritten ? null : _selectedButtonStyle(context),
                onPressed: () => setState(() => _showHandwritten = false),
                child: const Text('Typed'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: _showHandwritten ? _selectedButtonStyle(context) : null,
                onPressed: () => setState(() => _showHandwritten = true),
                child: const Text('Handwritten'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: !_showHandwritten
                ? Center(
                    child: Text(
                      entry.typedCharacter,
                      style: const TextStyle(fontSize: 96),
                    ),
                  )
                : entry.handwrittenSample != null
                    ? Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey)),
                        child: HandwritingCanvas(
                          readOnly: true,
                          initialStrokes: entry.handwrittenSample,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No handwriting saved yet'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _redrawHandwriting(entry),
                            child: const Text('Draw now'),
                          ),
                        ],
                      ),
          ),
          if (_showHandwritten && entry.handwrittenSample != null)
            TextButton(
              onPressed: () => _redrawHandwriting(entry),
              child: const Text('Redraw'),
            ),
          if (!_showHandwritten)
            TextButton(
              onPressed: () => _editTypedCharacter(entry),
              child: const Text('Edit character'),
            ),
        ],
      ),
    );
  }

  Widget _buildTranslationWindow(CharacterEntry entry) {
    final stats = entry.flashcardStats;
    final totalAnswered = stats.timesCorrect + stats.timesIncorrect;
    final accuracyText = totalAnswered == 0
        ? '—'
        : '${(stats.timesCorrect / totalAnswered * 100).round()}%';
    Color? accuracyColor;
    if (totalAnswered > 0) {
      final pct = stats.timesCorrect / totalAnswered * 100;
      if (pct < 40) {
        accuracyColor = AppColors.danger;
      } else if (pct < 70) {
        accuracyColor = AppColors.warning;
      } else {
        accuracyColor = AppColors.success;
      }
    }
    final referenced = entry.referencedCharacterIds
        .map((id) {
          for (final c in widget.store.characters) {
            if (c.id == id) return c;
          }
          return null;
        })
        .whereType<CharacterEntry>()
        .toList();
    final query = _referenceSearchController.text.trim().toLowerCase();
    final searchResults = query.isEmpty
        ? <CharacterEntry>[]
        : widget.store.characters.where((c) {
            if (c.id == entry.id) return false;
            if (entry.referencedCharacterIds.contains(c.id)) return false;
            return c.definition.toLowerCase().contains(query);
          }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Definition',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editDefinition(entry),
              ),
            ],
          ),
          Text(
              entry.definition.isEmpty ? '(no definition yet)' : entry.definition),
          const Divider(height: 24),
          Text('Flashcard stats',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Seen: ${stats.timesSeen}'),
          Text(
              'Correct: ${stats.timesCorrect} / Incorrect: ${stats.timesIncorrect}'),
          Text(
            'Accuracy: $accuracyText',
            style: TextStyle(
              color: accuracyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(stats.lastReviewedAt == null
              ? 'Never reviewed yet'
              : 'Last reviewed: ${_formatDate(stats.lastReviewedAt!)}'),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Notes',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editNotes(entry),
              ),
            ],
          ),
          Text(entry.notes.isEmpty ? '(no notes)' : entry.notes),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child:
                    Text('Tags', style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editTags(entry),
              ),
            ],
          ),
          entry.tags.trim().isEmpty
              ? const Text('(no tags)')
              : TagChips(tags: entry.tags),
          const Divider(height: 24),
          Text('References', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (referenced.isEmpty) const Text('No references yet.'),
          for (final other in referenced)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(other.typedCharacter),
              subtitle: Text(
                other.definition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Replace (not push) this screen with the referenced one, so
              // following references never piles up screens: Back always
              // returns to the list you came from. See docs/backlog.md
              // ("Long back history", option A, 2026-09-19).
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CharacterDetailScreen(
                    store: widget.store,
                    characterId: other.id,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    _removeReference(entry, other.id, other.typedCharacter),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceSearchController,
            decoration: const InputDecoration(
              labelText: 'Search definitions to link a reference',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          // Adding a reference is deliberately instant/no-confirmation (the
          // second and last such exception in the app, alongside star/hard)
          // since browsing and linking related characters is meant to be
          // quick and exploratory. Only *removing* a reference confirms.
          for (final candidate in searchResults)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(candidate.typedCharacter),
              subtitle: Text(
                candidate.definition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.link),
              onTap: () async {
                await widget.store.addReference(entry.id, candidate.id);
                _referenceSearchController.clear();
                setState(() {});
              },
            ),
          const Divider(height: 24),
          _buildPhotosSection(entry),
        ],
      ),
    );
  }

  /// Photos of this character seen out and about: a row of thumbnails
  /// (tap to open) and an "add" tile. New photos are linked to this
  /// character; link more characters from the photo's own screen.
  Widget _buildPhotosSection(CharacterEntry entry) {
    final photos = widget.store.photosFor(entry.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final photo in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(
                          store: widget.store,
                          photoId: photo.id,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: PhotoImage(store: widget.store, photo: photo),
                      ),
                    ),
                  ),
                ),
              InkWell(
                onTap: () => _addPhoto(entry),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addPhoto(CharacterEntry entry) async {
    final file = await pickPhoto(context);
    if (file == null) return;
    await widget.store.addPhoto(file, characterIds: [entry.id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Photo added. Tap it to add a note or link more '
          'characters.'),
    ));
  }

  Widget _buildBottomActions(CharacterEntry entry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleArchiveToggle(entry),
                  icon: Icon(
                      entry.isArchived ? Icons.unarchive : Icons.archive),
                  label: Text(entry.isArchived ? 'Unarchive' : 'Archive'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => _handleDelete(entry),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
