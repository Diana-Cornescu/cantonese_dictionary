import 'dart:math';

// material.dart only re-exports part of foundation, and setEquals isn't in
// that part.
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../data/stroke_reference.dart';
import '../../theme/app_color_roles.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/reference_glyph_painter.dart';
import '../flashcards/flashcard_mode_screen.dart' show CardPool;
import '../settings/settings_button.dart';

/// Writing practice: the Write tab (added 2026-09-25, in the slot Tags
/// used to have). See `docs/decisions/writing-practice.md`.
///
/// A card shows a definition. You write the character in a square box
/// (with a faint 米字格 guide), then tap **Check**: the correct form, from
/// the bundled [StrokeReference] data, appears in pale grey *under* your
/// ink, so you can see where your strokes are off. **Next** moves on;
/// **Try again** clears the box for another go at the same character.
///
/// **Nothing is marked or saved.** No score and no stats, on purpose for
/// the first version: see how it feels first. Flashcard stats aren't
/// touched either.
///
/// An entry with several characters (时间) is written one at a time in the
/// same box, "1 of 2" then "2 of 2", each with its own Check.
///
/// Entries the stroke data can't check are **skipped**: no typed text, or
/// any character missing from the data (many Cantonese-only characters —
/// 咗, 冇, 佢 — aren't in it). The options panel lists them. Entries with
/// no definition are left out too, since the definition is the prompt.
///
/// Options live in a panel that the bottom bar's round **…** button opens
/// and closes, like Flashcards: **All characters**, **Hard only** or
/// **Favorites only**. The choice isn't saved; each app start begins with
/// All characters.
class WritePracticeScreen extends StatefulWidget {
  const WritePracticeScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<WritePracticeScreen> createState() => WritePracticeScreenState();
}

/// Public so the bottom bar can call [openOptions] and [refreshCards].
class WritePracticeScreenState extends State<WritePracticeScreen> {
  final _random = Random();

  /// Null until the stroke data has loaded.
  StrokeReference? _reference;
  bool _loadFailed = false;

  CardPool _cardPool = CardPool.all;

  List<CharacterEntry> _pool = [];

  /// Entries the current options would include but the stroke data can't
  /// check. Shown in the options panel.
  List<CharacterEntry> _skipped = [];

  int _index = 0;

  /// Which character of the current entry is being written.
  int _glyph = 0;

  bool _checked = false;

  /// What's been written in the box so far.
  List<List<StrokePoint>> _strokes = [];

  /// Bumped by Try again, so the box starts empty again.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _loadReference();
  }

  Future<void> _loadReference() async {
    try {
      final reference = await StrokeReference.load();
      if (!mounted) return;
      setState(() {
        _reference = reference;
        _loadFailed = false;
        _rebuildPool();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  List<String> get _currentGlyphs =>
      StrokeReference.glyphsOf(_pool[_index].typedCharacter);

  /// Every character the current options allow, unshuffled, split into the
  /// ones the stroke data can check and the ones it can't.
  ({List<CharacterEntry> usable, List<CharacterEntry> skipped})
      _eligibleCards() {
    final reference = _reference;
    final List<CharacterEntry> source = switch (_cardPool) {
      CardPool.all => widget.store.activeCharacters,
      CardPool.hard => widget.store.hardCharacters,
      CardPool.favorites =>
        widget.store.activeCharacters.where((c) => c.isStarred).toList(),
    };
    final usable = <CharacterEntry>[];
    final skipped = <CharacterEntry>[];
    for (final card in source) {
      if (card.definition.trim().isEmpty) continue;
      final glyphs = StrokeReference.glyphsOf(card.typedCharacter);
      final checkable = reference != null &&
          glyphs.isNotEmpty &&
          glyphs.every(reference.covers);
      (checkable ? usable : skipped).add(card);
    }
    return (usable: usable, skipped: skipped);
  }

  /// A freshly shuffled pool from the current options, starting at the
  /// first card.
  void _rebuildPool() {
    final eligible = _eligibleCards();
    _pool = eligible.usable..shuffle(_random);
    _skipped = eligible.skipped;
    _index = 0;
    _resetCard();
  }

  /// Back to the first character of the current card, box empty.
  void _resetCard() {
    _glyph = 0;
    _resetBox();
  }

  void _resetBox() {
    _checked = false;
    _strokes = [];
    _attempt++;
  }

  /// Called by the bottom bar whenever this tab is shown again, like
  /// Flashcards: same set of characters → carry on (with any edits shown);
  /// a different set → reshuffle and start from the top.
  void refreshCards() {
    if (!mounted || _reference == null) return;
    final eligible = _eligibleCards();
    final eligibleIds = {for (final c in eligible.usable) c.id};
    final poolIds = {for (final c in _pool) c.id};
    setState(() {
      if (!setEquals(eligibleIds, poolIds)) {
        _rebuildPool();
        return;
      }
      _skipped = eligible.skipped;
      final byId = {for (final c in eligible.usable) c.id: c};
      final before = _pool.isEmpty ? null : _pool[_index].typedCharacter;
      _pool = [for (final c in _pool) byId[c.id]!];
      // The current entry's text was edited: start it again.
      if (before != null && before != _pool[_index].typedCharacter) {
        _resetCard();
      }
    });
  }

  /// Whether the options panel is showing. A plain flag, set before it
  /// opens and cleared once it has closed, for the reason given on
  /// `FlashcardModeScreenState.optionsOpen`.
  bool _optionsOpen = false;

  bool get optionsOpen => _optionsOpen;

  /// Closes the options panel, if it's open (… again, or switching tabs).
  void closeOptions() {
    if (!_optionsOpen || !mounted) return;
    Navigator.of(context).pop();
  }

  /// The options panel, opened by the bottom bar's round … button.
  Future<void> openOptions() async {
    if (_optionsOpen) return;
    _optionsOpen = true;
    try {
      await _showOptionsSheet();
    } finally {
      _optionsOpen = false;
    }
  }

  Future<void> _showOptionsSheet() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text('Which cards',
                        style: theme.textTheme.titleMedium),
                  ),
                  for (final pool in CardPool.values)
                    ListTile(
                      leading: Icon(pool == _cardPool
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                      title: Text(pool.label),
                      trailing: pool.icon == null
                          ? null
                          : Icon(pool.icon, color: pool.color),
                      selected: pool == _cardPool,
                      onTap: () {
                        _setCardPool(pool);
                        setSheetState(() {});
                      },
                    ),
                  if (_skipped.isNotEmpty) ...[
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Text(_skippedSummary(),
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// "Skipped, not in the stroke data yet: 咗  冇  佢", then "And 2
  /// characters with no typed text." if there are any.
  String _skippedSummary() {
    final missing = <String>[];
    var untyped = 0;
    for (final card in _skipped) {
      if (StrokeReference.glyphsOf(card.typedCharacter).isEmpty) {
        untyped++;
      } else {
        missing.add(card.typedCharacter.trim());
      }
    }
    final parts = <String>[];
    if (missing.isNotEmpty) {
      parts.add('Skipped, not in the stroke data yet: ${missing.join('  ')}');
    }
    if (untyped > 0) {
      final which = untyped == 1 ? '1 character' : '$untyped characters';
      parts.add(missing.isEmpty
          ? 'Skipped: $which with no typed text.'
          : 'And $which with no typed text.');
    }
    return parts.join('\n\n');
  }

  void _setCardPool(CardPool value) {
    if (value == _cardPool) return;
    setState(() {
      _cardPool = value;
      _rebuildPool();
    });
  }

  void _check() => setState(() => _checked = true);

  void _tryAgain() => setState(_resetBox);

  void _next() {
    setState(() {
      if (_glyph + 1 < _currentGlyphs.length) {
        _glyph++;
        _resetBox();
        return;
      }
      _index++;
      if (_index >= _pool.length) {
        _pool = List<CharacterEntry>.of(_pool)..shuffle(_random);
        _index = 0;
      }
      _resetCard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write'),
        actions: [SettingsButton(store: widget.store)],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loadFailed) {
      return _centeredMessage(
        "Couldn't load the stroke data.",
        action: OutlinedButton(
          onPressed: () {
            setState(() => _loadFailed = false);
            _loadReference();
          },
          child: const Text('Try again'),
        ),
      );
    }
    if (_reference == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pool.isEmpty) {
      final base = switch (_cardPool) {
        CardPool.hard => 'No hard-flagged characters to write.',
        CardPool.favorites => 'No favorites to write.',
        CardPool.all => 'No characters to write yet — add some first.',
      };
      final count = _skipped.length;
      final skippedNote = count == 0
          ? ''
          : count == 1
              ? '\n\n1 character was skipped because the stroke data '
                  "doesn't have it. Tap … below to see which."
              : '\n\n$count characters were skipped because the stroke '
                  "data doesn't have them. Tap … below to see which.";
      return _centeredMessage(
        base + skippedNote,
        action: _cardPool == CardPool.all
            ? null
            : OutlinedButton(
                onPressed: () => _setCardPool(CardPool.all),
                child: const Text('Show all characters instead'),
              ),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      // Square, as big as fits under the prompt and above the buttons.
      // No scrolling: a scroll view would fight the pen for vertical drags.
      final fits = min(constraints.maxWidth - 32, constraints.maxHeight - 270);
      final side = max(120.0, min(360.0, fits));
      return _buildCard(side);
    });
  }

  Widget _buildCard(double side) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final card = _pool[_index];
    final glyphs = _currentGlyphs;
    final glyph = glyphs[_glyph];
    return Column(
      children: [
        const SizedBox(height: 8),
        Text('${_index + 1} / ${_pool.length}'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            card.definition,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 4),
        // Always takes a line, so the box doesn't jump between cards.
        Text(
          glyphs.length > 1
              ? 'Character ${_glyph + 1} of ${glyphs.length}'
              : '',
          style: theme.textTheme.labelSmall?.copyWith(color: colors.faintText),
        ),
        const SizedBox(height: 8),
        Container(
          width: side,
          height: side,
          decoration: BoxDecoration(border: Border.all(color: colors.frame)),
          child: HandwritingCanvas(
            // A new key whenever the box should start over, or switch to
            // showing the checked result: the canvas keeps its own copy of
            // the strokes, taken when it's created.
            key: ValueKey('$_index/$_glyph/$_attempt/$_checked'),
            readOnly: _checked,
            initialStrokes: _checked ? _strokes : null,
            onStrokesChanged: (strokes) => _strokes = strokes,
            backgroundPainter: WritingGuidePainter(
              guideColor: colors.writingGuide,
              reference: _checked ? _reference!.strokesFor(glyph) : null,
              referenceColor: colors.referenceInk,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // The answer as text, once checked; blank space before, so the
        // buttons stay put.
        SizedBox(
          height: 48,
          child: Center(
            child: _checked
                ? Text(glyph, style: const TextStyle(fontSize: 36))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        if (_checked)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _tryAgain,
                child: const Text('Try again'),
              ),
              FilledButton(
                onPressed: _next,
                child: Text(_glyph + 1 < glyphs.length
                    ? 'Next character'
                    : 'Next'),
              ),
            ],
          )
        else
          FilledButton(onPressed: _check, child: const Text('Check')),
      ],
    );
  }

  Widget _centeredMessage(String text, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
