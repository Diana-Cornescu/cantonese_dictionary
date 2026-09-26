import 'dart:math';

// material.dart only re-exports part of foundation, and setEquals isn't in
// that part.
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_color_roles.dart';
import '../../theme/app_colors.dart';
import '../../widgets/handwriting_canvas.dart';
import '../../widgets/language_icon.dart';
import '../../widgets/practice_layout.dart';
import '../../widgets/typed_character.dart';
import '../character_detail/character_detail_screen.dart';
import '../settings/settings_button.dart';

/// Which way a single card is asked.
enum CardDirection {
  /// Front: typed character + your drawing. Back: definition.
  characterToDefinition,

  /// Front: definition. Back: typed character + your drawing.
  definitionToCharacter,
}

/// The study mode chosen in the dropdown.
enum StudyDirection {
  characterToDefinition('Character → Definition'),
  definitionToCharacter('Definition → Character'),

  /// Each card randomly picks one of the two directions.
  bidirectional('Bidirectional');

  const StudyDirection(this.label);
  final String label;
}

/// Which characters are practised, chosen in the options panel.
enum CardPool {
  // No icon: only the two filters get one (2026-09-25).
  all('All characters', null, null),
  hard('Hard only', Icons.local_fire_department, AppColors.danger),
  favorites('Favorites only', Icons.star, AppColors.star);

  const CardPool(this.label, this.icon, this.color);
  final String label;
  final IconData? icon;
  final Color? color;
}

/// What the character side of a card shows, chosen in the options panel.
///
/// Recognising your own handwriting is a way of cheating: it doesn't
/// generalise to the same character printed on a menu. **Text only** takes
/// that crutch away. Added 2026-09-20.
///
/// **Text only is the default and listed first** (2026-09-25; it was Text +
/// drawing). The order here is the order in the options panel. It's safe
/// to reorder: the setting is saved by name, not position.
enum CharacterFace {
  typedOnly('Text only', Icons.text_fields),
  typedAndDrawing('Text + drawing', Icons.draw_outlined);

  const CharacterFace(this.label, this.icon);
  final String label;
  final IconData icon;

  /// The key this choice is saved under in the settings table, so it
  /// survives a restart and rides along in backups — the same mechanism
  /// the color theme uses.
  static const settingKey = 'flashcard_character_face';

  /// The choice stored under [settingKey]. Anything unrecognised (never
  /// set, or written by a newer version) falls back to [typedOnly]. A
  /// choice someone already saved is kept.
  ///
  /// The stored string is the enum's `name`, so **renaming a constant here
  /// silently resets everyone's setting** — `test/flashcard_face_test.dart`
  /// pins the two strings for that reason.
  static CharacterFace byId(String? id) {
    for (final face in values) {
      if (face.name == id) return face;
    }
    return typedOnly;
  }
}

/// Flashcard practice (see docs/decisions_log.md, 2026-09-20).
///
/// The Flashcards tab. Its options live in a panel that the bottom bar's
/// round **…** button opens and closes (1.6.0; they were three dropdown
/// pills across the top before, and nothing about them shows on the screen
/// now):
///  - which cards: **All characters**, **Hard only** or **Favorites only**,
///  - which language (2026-09-26): three checkboxes, **Cantonese**,
///    **Mandarin** and **Language not set**, all checked to start with.
///    Unchecking one leaves those cards out; a word marked both stays in
///    while either language is checked. Combines with the choice above,
///    so Hard only with just Mandarin checked is the hard Mandarin words,
///  - which way: **Character → Definition**, **Definition → Character** or
///    **Bidirectional** (each card randomly picks a direction),
///  - what the character side shows: **Text + drawing** or **Text only**.
///
/// Each app start begins with All characters, every language box checked
/// and Character → Definition. Changing any of those reshuffles and starts from the top.
/// The last one (character side) is only about what's drawn on the card,
/// so it doesn't reshuffle — and unlike the others it is **remembered
/// between sessions**, because it's a standing preference about how you want to be
/// tested rather than a per-session choice.
///
/// Since the tab stays alive while you use the others (1.6.0), a round in
/// progress survives switching tabs. [refreshCards] runs each time the tab
/// is shown again, so characters added, deleted or re-flagged elsewhere
/// are picked up.
///
/// **Layout** (2026-09-26, shared with Write via
/// `widgets/practice_layout.dart`): under the card, its language (name +
/// emblem) and **Go to character screen** (hidden, but still taking its
/// space, until the card is revealed); along the bottom, above the
/// navigation bar, **Incorrect / Correct**, or the "tap the card" hint
/// until it's revealed.
///
/// Both directions add to the same seen/correct/incorrect stats.
class FlashcardModeScreen extends StatefulWidget {
  const FlashcardModeScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<FlashcardModeScreen> createState() => FlashcardModeScreenState();
}

/// Public so the bottom bar can call [openOptions] and [refreshCards].
class FlashcardModeScreenState extends State<FlashcardModeScreen> {
  final _random = Random();

  CardPool _cardPool = CardPool.all;
  /// The checked Language boxes. All three by default.
  Set<LanguageFilter> _languages = LanguageFilter.all;

  bool get _allLanguages =>
      _languages.length == LanguageFilter.values.length;
  StudyDirection _study = StudyDirection.characterToDefinition;
  late CharacterFace _face =
      CharacterFace.byId(widget.store.setting(CharacterFace.settingKey));

  bool get _charToDef => _study != StudyDirection.definitionToCharacter;
  bool get _defToChar => _study != StudyDirection.characterToDefinition;

  List<CharacterEntry> _pool = [];
  int _index = 0;
  bool _revealed = false;
  CardDirection _direction = CardDirection.characterToDefinition;

  @override
  void initState() {
    super.initState();
    _rebuildPool();
  }

  /// Builds a freshly shuffled pool from the current toggles and shows the
  /// first card. Characters without a definition (only possible for ones
  /// made before definitions became required) can't be asked Definition →
  /// Character, so they're left out when that's the only direction on.
  void _rebuildPool() {
    _pool = _eligibleCards()..shuffle(_random);
    _index = 0;
    _revealed = false;
    _pickDirection();
  }

  /// Every character the current options allow, unshuffled.
  List<CharacterEntry> _eligibleCards() {
    final List<CharacterEntry> source = switch (_cardPool) {
      CardPool.all => widget.store.activeCharacters,
      CardPool.hard => widget.store.hardCharacters,
      CardPool.favorites =>
        widget.store.activeCharacters.where((c) => c.isStarred).toList(),
    };
    return source
        .where((c) => LanguageFilter.anyMatch(_languages, c))
        .where((c) => _charToDef || c.definition.trim().isNotEmpty)
        .toList();
  }

  /// Called by the bottom bar whenever this tab is shown again. If the
  /// same characters are still in play, the round carries on where it was,
  /// with any edits to them shown. If characters were added, removed or
  /// re-flagged so the set changed, it reshuffles and starts from the top.
  void refreshCards() {
    if (!mounted) return;
    final eligible = _eligibleCards();
    final eligibleIds = {for (final c in eligible) c.id};
    final poolIds = {for (final c in _pool) c.id};
    setState(() {
      if (!setEquals(eligibleIds, poolIds)) {
        _rebuildPool();
        return;
      }
      final byId = {for (final c in eligible) c.id: c};
      _pool = [for (final c in _pool) byId[c.id]!];
    });
  }

  /// Whether the options panel is showing. Set just before it opens and
  /// cleared once it has closed, however it was closed (… again, tapping
  /// outside it, swiping it down, Back).
  ///
  /// A plain flag on purpose. The first version (2026-09-25) remembered the
  /// panel's context from inside its builder instead, but the panel is
  /// rebuilt on every frame of its closing animation, which put the context
  /// back after it had been cleared: the app then believed the panel was
  /// still open, and … stopped working after the first use.
  bool _optionsOpen = false;

  bool get optionsOpen => _optionsOpen;

  /// Closes the options panel, if it's open. Used by the … button (a second
  /// tap closes it) and when you switch to another tab. The panel is modal,
  /// so while it's open it is the top screen in this tab and pop closes it.
  void closeOptions() {
    if (!_optionsOpen || !mounted) return;
    Navigator.of(context).pop();
  }

  /// The options panel, opened by the bottom bar's round … button; tapping
  /// … again closes it (so does tapping outside it, or swiping it down).
  /// Each choice applies straight away; the panel stays open so you can
  /// change several.
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
          Widget heading(String text) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child:
                    Text(text, style: Theme.of(context).textTheme.titleMedium),
              );
          // A ListTile drawn as a radio button (RadioListTile's groupValue
          // is deprecated in this Flutter version).
          Widget choice<T>({
            required T value,
            required T current,
            required String label,
            required void Function(T) onPick,
            Widget? trailing,
          }) =>
              ListTile(
                leading: Icon(value == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(label),
                trailing: trailing,
                selected: value == current,
                onTap: () {
                  onPick(value);
                  setSheetState(() {});
                },
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
                    choice<CardPool>(
                      value: pool,
                      current: _cardPool,
                      label: pool.label,
                      trailing: pool.icon == null
                          ? null
                          : Icon(pool.icon, color: pool.color),
                      onPick: _setCardPool,
                    ),
                  const Divider(height: 24),
                  heading('Language'),
                  for (final language in LanguageFilter.values)
                    CheckboxListTile(
                      value: _languages.contains(language),
                      title: Text(language.label),
                      // The same emblems as on the cards; none for
                      // "not set".
                      secondary: switch (language) {
                        LanguageFilter.cantonese =>
                          const LanguageIcon(LanguageEmblem.cantonese),
                        LanguageFilter.mandarin =>
                          const LanguageIcon(LanguageEmblem.mandarin),
                        LanguageFilter.notSet => null,
                      },
                      onChanged: (checked) {
                        _toggleLanguage(language, checked ?? false);
                        setSheetState(() {});
                      },
                    ),
                  const Divider(height: 24),
                  heading('Direction'),
                  for (final study in StudyDirection.values)
                    choice<StudyDirection>(
                      value: study,
                      current: _study,
                      label: study.label,
                      onPick: _setStudy,
                    ),
                  const Divider(height: 24),
                  heading('Character side'),
                  for (final face in CharacterFace.values)
                    choice<CharacterFace>(
                      value: face,
                      current: _face,
                      label: face.label,
                      trailing: Icon(face.icon),
                      onPick: _setFace,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Chooses the direction for the current card.
  void _pickDirection() {
    if (_pool.isEmpty) return;
    final card = _pool[_index];
    final canAskDefinition = card.definition.trim().isNotEmpty;
    final options = [
      if (_charToDef) CardDirection.characterToDefinition,
      if (_defToChar && canAskDefinition) CardDirection.definitionToCharacter,
    ];
    _direction = options.isEmpty
        ? CardDirection.characterToDefinition
        : options[_random.nextInt(options.length)];
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

  /// Unlike the other choices, this one is saved: it's a standing preference,
  /// and it changes nothing about the pool, so no reshuffle.
  Future<void> _setFace(CharacterFace value) async {
    if (value == _face) return;
    setState(() => _face = value);
    await widget.store.setSetting(CharacterFace.settingKey, value.name);
  }

  void _setStudy(StudyDirection value) {
    if (value == _study) return;
    setState(() {
      _study = value;
      _rebuildPool();
    });
  }

  void _next() {
    setState(() {
      _index++;
      if (_index >= _pool.length) {
        _pool = List<CharacterEntry>.of(_pool)..shuffle(_random);
        _index = 0;
      }
      _revealed = false;
      _pickDirection();
    });
  }

  Future<void> _answer(bool correct) async {
    final current = _pool[_index];
    await widget.store.recordReview(current.id, correct: correct);
    _next();
  }

  /// Opens [card]'s character screen. When you come back, the same card is
  /// still showing, refreshed with any edits (or skipped if you deleted it).
  Future<void> _openCharacter(CharacterEntry card) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CharacterDetailScreen(store: widget.store, characterId: card.id),
      ),
    );
    if (!mounted || _pool.isEmpty) return;
    CharacterEntry? fresh;
    for (final c in widget.store.characters) {
      if (c.id == card.id) fresh = c;
    }
    setState(() {
      if (fresh != null) {
        _pool[_index] = fresh;
      } else {
        // Deleted while away: drop it and move on.
        _pool.removeAt(_index);
        if (_index >= _pool.length) _index = 0;
        _revealed = false;
        _pickDirection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard mode'),
        actions: [SettingsButton(store: widget.store)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(child: _buildBody()),
              ),
            ),
            // Pinned just above the bottom navigation bar (2026-09-26),
            // like Write's buttons.
            if (_pool.isNotEmpty) _buildActionBar(),
          ],
        ),
      ),
    );
  }

  /// Incorrect / Correct once the card is revealed; until then, the hint
  /// to tap the card, in the same spot so nothing moves.
  Widget _buildActionBar() {
    final askingCharacter =
        _direction == CardDirection.definitionToCharacter;
    return PracticeActionBar(
      buttons: !_revealed
          ? const []
          : [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.onAccent,
                ),
                onPressed: () => _answer(false),
                child: const FittedLabel('Incorrect'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onAccent,
                ),
                onPressed: () => _answer(true),
                child: const FittedLabel('Correct'),
              ),
            ],
      placeholder: Text(
        askingCharacter
            ? 'Tap the card to reveal the character'
            : 'Tap the card to reveal the definition',
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBody() {
    if (_pool.isEmpty) {
      final filtered = _cardPool != CardPool.all || !_allLanguages;
      final message = !_allLanguages
          ? 'No characters match these options — change the language or '
              'which cards with the … button below.'
          : switch (_cardPool) {
              CardPool.hard =>
                'No hard-flagged characters yet — flag some with the 🔥 '
                    'button first.',
              CardPool.favorites =>
                'No favorites yet — star some characters with the ☆ button '
                    'first.',
              CardPool.all => 'No characters to study yet — add some first.',
            };
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (filtered) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _showAll,
                child: const Text('Show all characters instead'),
              ),
            ],
          ],
        ),
      );
    }

    final current = _pool[_index];
    final askingCharacter =
        _direction == CardDirection.definitionToCharacter;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_index + 1} / ${_pool.length}'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: Container(
              width: 280,
              height: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: context.appColors.frame),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Which way this card is asked, so mixed mode is clear.
                  Text(
                    askingCharacter
                        ? 'Definition → Character'
                        : 'Character → Definition',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: context.appColors.faintText),
                  ),
                  Expanded(
                    child: Center(
                      child: _cardFace(current,
                          showCharacter: askingCharacter == _revealed),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Under the card (2026-09-26), the same as under Write's box: the
          // card's language(s), then Go to character screen. Both keep
          // their space when empty or hidden, so nothing jumps.
          LanguageLine(
            isCantonese: current.isCantonese,
            isMandarin: current.isMandarin,
            color: context.appColors.activeIcon,
          ),
          // Opens this card's character screen; Back returns to this same
          // card (2026-09-20). Only shown once the card is revealed, so it
          // can't give the answer away.
          GoToCharacterLink(
            visible: _revealed,
            onPressed: () => _openCharacter(current),
          ),
        ],
      ),
    );
  }

  /// One side of the card. [showCharacter] is true for the character side
  /// (the front in Character → Definition, the answer in Definition →
  /// Character). The character side shows the typed character, and your
  /// drawing under it unless the third pill is set to **Text only**.
  Widget _cardFace(CharacterEntry card, {required bool showCharacter}) {
    if (!showCharacter) {
      return Text(
        card.definition.isEmpty ? '(no definition yet)' : card.definition,
        textAlign: TextAlign.center,
      );
    }
    final strokes = card.handwrittenSample;
    // Typed character plus your drawing underneath, whichever side of the
    // card the character is on (question in Character → Definition, answer
    // in Definition → Character). Since 2026-09-20.
    //
    // Text only hides the drawing everywhere it would appear, on both the
    // question and the answer side — half-hiding it would just move the
    // crutch rather than remove it.
    final hasDrawing = _face == CharacterFace.typedAndDrawing &&
        strokes != null &&
        strokes.isNotEmpty;
    if (!hasDrawing) {
      return TypedCharacterText(
        text: card.typedCharacter,
        style: const TextStyle(fontSize: 72),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TypedCharacterText(
          text: card.typedCharacter,
          style: const TextStyle(fontSize: 56),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          height: 120,
          child: HandwritingCanvas(
            readOnly: true,
            initialStrokes: strokes,
            fitToBox: true,
          ),
        ),
      ],
    );
  }
}
