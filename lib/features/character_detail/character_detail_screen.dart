import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../data/photo_entry.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_picker_dialog.dart';
import '../../widgets/text_prompt_dialog.dart';
import '../photos/photo_image.dart';
import '../photos/photo_picking.dart';
import '../photos/photo_viewer_screen.dart';
import '../tags/tag_detail_screen.dart';

/// Detail screen for one character: a character window (typed/handwritten
/// toggle) and a translation window (definition, flashcard stats, notes,
/// tags, references), side by side on wide screens or stacked on narrow
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

/// Which face of the character the box at the top is showing.
///
/// Was a single `_showHandwritten` bool until 2026-09-21, when photos
/// became the third option.
enum _CharacterView { typed, handwritten, photos }

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  _CharacterView _view = _CharacterView.typed;
  final _referenceSearchController = TextEditingController();

  /// Drives the photo carousel. The arrows either side of the box animate
  /// it; a swipe moves it directly and reports back through onPageChanged.
  final _photoPageController = PageController();
  int _photoPage = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
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

  /// Delegates to the shared dialog, which owns (and disposes) its own
  /// controller — see `widgets/text_prompt_dialog.dart`.
  Future<String?> _promptForText(
    String title,
    String initialValue, {
    int maxLines = 5,
  }) =>
      promptForText(
        context,
        title: title,
        initialValue: initialValue,
        maxLines: maxLines,
      );

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
    // One line, so Enter saves and closes the keyboard (2026-09-20).
    // Notes keep their multi-line box — that's where longer writing goes.
    final newValue = await _promptForText(
      'Edit definition',
      entry.definition,
      maxLines: 1,
    );
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

  /// Tags are chosen from the ones that already exist (2026-09-20), rather
  /// than retyped as free text, so "food" doesn't end up alongside "Food".
  /// The picker can still create a new tag by typing it.
  Future<void> _editTags(CharacterEntry entry) async {
    final chosen = await pickTags(
      context,
      widget.store,
      initial: parseTags(entry.tags),
      title: "Tags for '${entry.typedCharacter}'",
    );
    if (chosen == null) return;
    final newValue = chosen.join(', ');
    if (newValue == entry.tags) return;
    if (!mounted) return;
    final confirmed = await confirmAction(
      context,
      title: 'Save tags?',
      message: "Save changes to the tags for '${entry.typedCharacter}'?",
    );
    if (confirmed) {
      await widget.store.updateCharacter(entry.copyWith(tags: newValue));
    }
  }

  /// Opens the tag's own screen, the way a photo's linked characters open
  /// theirs.
  void _openTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TagDetailScreen(store: widget.store, tag: tag),
      ),
    );
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

  /// Which face of the box is showing — Typed / Handwritten / Photos. The
  /// selected one fills with the current color theme.
  ///
  /// These stay theme-colored on purpose. They pick a view; they aren't
  /// flags on the character, so they have no gold or red of their own to
  /// compete with, and the theme fill is the one splash of color on the
  /// screen.
  ButtonStyle _selectedButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  /// The look of the **Favorite / Hard** pair under the box.
  ///
  /// Selected: a **black outline**, a **pale grey background**, the icon in
  /// its own color (gold star, red fire) and a dark grey label.
  /// Unselected: light grey throughout — outline, icon and label.
  ///
  /// Exactly what `FilterIconButton` does on the list screens. These two
  /// are the same flags shown in the same colors, so they look the same
  /// wherever they appear, and nothing about them is theme-colored
  /// (2026-09-21): they used to fill with `primaryContainer`, which changed
  /// with every color theme and competed with the gold and red.
  ButtonStyle _toggleButtonStyle(bool selected) {
    return OutlinedButton.styleFrom(
      // Sets the label, and the icon too — the icons pass a color only
      // when they're on, so unselected they inherit this grey.
      foregroundColor: selected ? AppColors.ironGrey : AppColors.inactive,
      backgroundColor: selected ? AppColors.selectedFill : null,
      side: BorderSide(
        color: selected ? AppColors.selectedOutline : AppColors.inactive,
        width: selected ? 1.5 : 1,
      ),
    );
  }

  /// One of the three buttons above the box. The selected one fills with
  /// the color theme — see [_selectedButtonStyle].
  Widget _viewButton(_CharacterView view, String label) {
    return OutlinedButton(
      style: _view == view ? _selectedButtonStyle(context) : null,
      onPressed: () => setState(() => _view = view),
      child: Text(label),
    );
  }

  /// Steps the carousel, **wrapping around** at either end: forward from
  /// the last photo lands on the first (2026-09-21).
  ///
  /// A wrap is a [jumpToPage], not an animation — animating from the last
  /// photo to the first would scroll backwards past every photo in between,
  /// which looks like the arrow did the opposite of what you asked. Normal
  /// steps still animate.
  void _movePhoto(int delta, int count) {
    if (count < 2) return;
    final next = (_photoPage + delta) % count; // Dart's % is never negative
    final wrapping = (delta > 0 && _photoPage == count - 1) ||
        (delta < 0 && _photoPage == 0);
    if (wrapping) {
      _photoPageController.jumpToPage(next);
    } else {
      _photoPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// A round, outlined arrow either side of the carousel. It both says
  /// "this swipes" and does the swipe, for anyone who'd rather tap.
  /// Chosen over dots (2026-09-21).
  ///
  /// Only disabled when there is nothing to move between — one photo, or
  /// none. Otherwise both arrows always work, because the run wraps.
  Widget _carouselArrow({
    required bool forward,
    required bool enabled,
    required int count,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: forward ? 'Next photo' : 'Previous photo',
        onPressed: enabled ? () => _movePhoto(forward ? 1 : -1, count) : null,
        icon: Icon(forward ? Icons.chevron_right : Icons.chevron_left),
        style: IconButton.styleFrom(
          shape: CircleBorder(side: BorderSide(color: colors.outline)),
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// The carousel, flanked by its arrows. The arrows sit OUTSIDE the box
  /// (and only exist in this view), so the typed and handwritten faces keep
  /// the exact layout they always had.
  Widget _buildPhotoRow(CharacterEntry entry, List<PhotoEntry> photos) {
    // Both arrows stay live whenever there's more than one photo, since
    // the run wraps; with a single photo there is nowhere to go.
    final canMove = photos.length > 1;
    return Row(
      children: [
        if (photos.isNotEmpty)
          _carouselArrow(
            forward: false,
            enabled: canMove,
            count: photos.length,
          ),
        Expanded(
          child: SizedBox(
            height: 240,
            child: _buildPhotoCarousel(entry, photos),
          ),
        ),
        if (photos.isNotEmpty)
          _carouselArrow(
            forward: true,
            enabled: canMove,
            count: photos.length,
          ),
      ],
    );
  }

  Widget _buildPhotoCarousel(CharacterEntry entry, List<PhotoEntry> photos) {
    // A photo can be deleted from its own screen while _photoPage still
    // points past the end of the list, so the index is corrected rather
    // than trusted.
    if (_photoPage >= photos.length) _photoPage = 0;
    if (photos.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No photos of this character yet'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _addPhoto(entry),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add photo'),
          ),
        ],
      );
    }
    return PageView.builder(
      controller: _photoPageController,
      itemCount: photos.length,
      onPageChanged: (index) => setState(() => _photoPage = index),
      itemBuilder: (context, index) {
        final photo = photos[index];
        return InkWell(
          // The photo's own screen is where the note, its other characters
          // and delete live; this is only a viewer.
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
            child: PhotoImage(
              store: widget.store,
              photo: photo,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterWindow(CharacterEntry entry) {
    final photos = widget.store.photosFor(entry.id);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Three faces of the same box: the typed character, your drawing,
          // and (2026-09-21) the photos linked to this character. A Wrap so
          // the third button drops to its own line rather than overflowing
          // on a narrow phone.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _viewButton(_CharacterView.typed, 'Typed'),
              _viewButton(_CharacterView.handwritten, 'Handwritten'),
              _viewButton(_CharacterView.photos, 'Photos'),
            ],
          ),
          const SizedBox(height: 16),
          if (_view == _CharacterView.photos)
            _buildPhotoRow(entry, photos)
          else
            SizedBox(
              height: 240,
              child: _view == _CharacterView.typed
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
          if (_view == _CharacterView.handwritten &&
              entry.handwrittenSample != null)
            TextButton(
              onPressed: () => _redrawHandwriting(entry),
              child: const Text('Redraw'),
            ),
          if (_view == _CharacterView.typed)
            TextButton(
              onPressed: () => _editTypedCharacter(entry),
              child: const Text('Edit character'),
            ),
          // The empty state has its own Add photo button, so this one only
          // shows when there's already something in the carousel.
          if (_view == _CharacterView.photos && photos.isNotEmpty)
            TextButton.icon(
              onPressed: () => _addPhoto(entry),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add photo'),
            ),
          const SizedBox(height: 8),
          // Favorite and hard, directly under the character box
          // (2026-09-20), so a character can be flagged while you're
          // looking at it instead of only from the list.
          //
          // Buttons with icon + label rather than bare icons, since in the
          // body of a screen an unlabelled icon doesn't say what it does.
          // They wear the grey/black/pale-fill look of the filter buttons
          // on the list screens, NOT the theme fill of the three view
          // buttons above — these are the same two flags, so they look the
          // same everywhere they appear. A Wrap, not a Row, so the two drop
          // onto separate lines instead of overflowing on a narrow phone.
          //
          // Instant and unconfirmed, like the same two flags on the list
          // rows: the app's one deliberate exception to "confirm before
          // committing an edit", since one more tap undoes them.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: _toggleButtonStyle(entry.isStarred),
                onPressed: () => widget.store.toggleStarred(entry.id),
                icon: Icon(
                  entry.isStarred ? Icons.star : Icons.star_border,
                  color: entry.isStarred ? AppColors.star : null,
                ),
                label: const Text('Favorite'),
              ),
              OutlinedButton.icon(
                style: _toggleButtonStyle(entry.isHard),
                onPressed: () => widget.store.toggleHard(entry.id),
                icon: Icon(
                  entry.isHard
                      ? Icons.local_fire_department
                      : Icons.local_fire_department_outlined,
                  color: entry.isHard ? AppColors.danger : null,
                ),
                label: const Text('Hard'),
              ),
            ],
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
              : TagChips(tags: entry.tags, onTagTap: _openTag),
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
        ],
      ),
    );
  }

  /// Adds a photo already linked to this character. `photosFor` is newest
  /// first, so the new one becomes page 0 and the carousel jumps to it.
  Future<void> _addPhoto(CharacterEntry entry) async {
    final file = await pickPhoto(context);
    if (file == null) return;
    await widget.store.addPhoto(file, characterIds: [entry.id]);
    if (!mounted) return;
    setState(() => _photoPage = 0);
    // After the frame: the PageView has to rebuild with the new photo in it
    // before the controller can be moved onto it. Without this the viewport
    // keeps its old offset and you'd be looking at a different photo than
    // the one you just took.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _photoPageController.hasClients) {
        _photoPageController.jumpToPage(0);
      }
    });
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
