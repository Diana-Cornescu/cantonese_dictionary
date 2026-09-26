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
/// A card shows a definition, always visible above a square box with a
/// faint 米字格 guide and the character's **X-ray** (from the bundled
/// [StrokeReference] data): each stroke's outline in pale grey, its centre
/// line with an arrow for the direction, and a numbered badge on it for
/// the order. You write over it, then **Next**.
///  - The stroke to write next is highlighted and the rest greyed; it
///    moves on each time you lift the pen (one pen-lift = one stroke), and
///    undo steps it back.
///  - An 👁 **Hide X-ray / Show X-ray** button next to Next turns the X-ray
///    off and on without clearing what you've written, to try a character
///    from memory and then check it. It stays as set from card to card,
///    until the app closes.
///
/// There used to be a separate Memory mode (write, then Check); the eye
/// button replaced it the same night (2026-09-26). Its code is kept in
/// `docs/archive/write-memory-mode.md`.
///
/// **Nothing is marked or saved.** No score and no stats, on purpose for
/// the first version: see how it feels first. Flashcard stats aren't
/// touched either.
///
/// An entry with several characters (时间) is written one at a time in the
/// same box, "1 of 2" then "2 of 2".
///
/// Entries the stroke data can't check are **skipped**: no typed text, or
/// any character missing from the data (many Cantonese-only characters —
/// 咗, 冇, 佢 — aren't in it). The options panel lists them. Entries with
/// no definition are left out too, since the definition is the prompt.
///
/// Options live in a panel that the bottom bar's round **…** button opens
/// and closes, like Flashcards: **All characters**, **Hard only** or
/// **Favorites only**, and (2026-09-26) three Language checkboxes,
/// **Cantonese**, **Mandarin** and **Language not set**, all checked to
/// start with; unchecking one leaves those cards out (a word marked both
/// stays in while either language is checked). The choices aren't saved;
/// each app start begins with All characters and every language checked.
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
  /// The checked Language boxes. All three by default.
  Set<LanguageFilter> _languages = LanguageFilter.all;

  bool get _allLanguages =>
      _languages.length == LanguageFilter.values.length;

  List<CharacterEntry> _pool = [];

  /// Entries the current options would include but the stroke data can't
  /// check. Shown in the options panel.
  List<CharacterEntry> _skipped = [];

  int _index = 0;

  /// Which character of the current entry is being written.
  int _glyph = 0;

  /// What's been written in the box so far.
  List<List<StrokePoint>> _strokes = [];

  /// The 👁 button: X-ray hidden. Carries over between cards;
  /// not saved (2026-09-26).
  bool _xrayHidden = false;

  /// Bumped whenever the box should start empty again.
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
      if (!LanguageFilter.anyMatch(_languages, card)) continue;
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
          Widget heading(String text) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(text, style: theme.textTheme.titleMedium),
              );
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading('Which cards'),
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
                  const Divider(height: 24),
                  heading('Language'),
                  for (final language in LanguageFilter.values)
                    CheckboxListTile(
                      value: _languages.contains(language),
                      title: Text(language.label),
                      onChanged: (checked) {
                        _toggleLanguage(language, checked ?? false);
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

  /// Checks or unchecks one Language box. Reshuffles, like the card pool.
  void _toggleLanguage(LanguageFilter language, bool checked) {
    if (_languages.contains(language) == checked) return;
    setState(() {
      _languages = {..._languages};
      if (checked) {
        _languages.add(language);
      } else {
        _languages.remove(language);
      }
      _rebuildPool();
    });
  }

  /// Back to every character: All characters and every language box.
  void _showAll() {
    setState(() {
      _cardPool = CardPool.all;
      _languages = LanguageFilter.all;
      _rebuildPool();
    });
  }

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
      final filtered = _cardPool != CardPool.all || !_allLanguages;
      final base = !_allLanguages
          ? 'No characters to write with these options.'
          : switch (_cardPool) {
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
        action: !filtered
            ? null
            : OutlinedButton(
                onPressed: _showAll,
                child: const Text('Show all characters instead'),
              ),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      // Square, as big as fits under the prompt and above the buttons.
      // No scrolling: a scroll view would fight the pen for vertical drags.
      final fits = min(constraints.maxWidth - 32, constraints.maxHeight - 220);
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
    final showXray = !_xrayHidden;
    final lastGlyph = _glyph + 1 >= glyphs.length;
    final next = FilledButton(
      onPressed: _next,
      child: Text(lastGlyph ? 'Next' : 'Next character'),
    );
    // Full width, so the column's children are centred across the screen.
    // A Column is only as wide as its widest child; the old answer row
    // (a Center) used to stretch it by accident, and when that row went
    // (2026-09-26) everything slid to the left edge.
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Always takes a line, so the box doesn't jump between cards.
          Text(
            glyphs.length > 1
                ? '${_index + 1} / ${_pool.length}  ·  '
                    'character ${_glyph + 1} of ${glyphs.length}'
                : '${_index + 1} / ${_pool.length}',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: colors.faintText),
          ),
          const SizedBox(height: 8),
          // The prompt sits right on top of the box and never goes away
          // (2026-09-26): the box is sized to leave room for it.
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
          const SizedBox(height: 8),
          Container(
            width: side,
            height: side,
            decoration: BoxDecoration(border: Border.all(color: colors.frame)),
            child: HandwritingCanvas(
              // A new key whenever the box should start over: the canvas keeps
              // its own copy of the strokes, taken when it's created.
              key: ValueKey('$_index/$_glyph/$_attempt'),
              readOnly: false,
              // Rebuilt on each stroke so the highlight moves on.
              onStrokesChanged: (strokes) => setState(() => _strokes = strokes),
              backgroundPainter: WritingGuidePainter(
                guideColor: colors.writingGuide,
                reference: showXray ? _reference!.glyphFor(glyph) : null,
                outlineColor: colors.referenceInk,
                strokeOrderColor: colors.strokeOrder,
                onStrokeOrderColor: colors.onStrokeOrder,
                mutedColor: colors.strokeOrderMuted,
                // The next stroke to write: as many as you've drawn so far.
                activeStroke: _strokes.length,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Hiding it keeps what's been written: the box's key doesn't
              // change, only its background.
              OutlinedButton.icon(
                onPressed: () => setState(() => _xrayHidden = !_xrayHidden),
                icon: Icon(_xrayHidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                label: Text(_xrayHidden ? 'Show X-ray' : 'Hide X-ray'),
              ),
              next,
            ],
          ),
        ],
      ),
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
