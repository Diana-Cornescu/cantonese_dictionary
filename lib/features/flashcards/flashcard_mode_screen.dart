import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/handwriting_canvas.dart';
import '../character_detail/character_detail_screen.dart';

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

/// Which characters are practised, chosen in the first dropdown.
enum CardPool {
  all('All characters', Icons.style_outlined, null),
  hard('Hard only', Icons.local_fire_department, AppColors.danger),
  favorites('Favorites only', Icons.star, AppColors.star);

  const CardPool(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color? color;
}

/// Flashcard practice (see docs/decisions_log.md, 2026-09-20).
///
/// Options bar at the top (redesigned 2026-09-20): two matching outlined
/// dropdown pills:
///  - which cards: **All characters**, **Hard only** or **Favorites only**,
///  - which way: **Character → Definition**, **Definition → Character** or
///    **Bidirectional** (each card randomly picks a direction).
///
/// Every time the screen opens it starts with All characters and Character
/// → Definition. Changing either option reshuffles and starts from the top.
/// Both directions add to the same seen/correct/incorrect stats.
class FlashcardModeScreen extends StatefulWidget {
  const FlashcardModeScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<FlashcardModeScreen> createState() => _FlashcardModeScreenState();
}

class _FlashcardModeScreenState extends State<FlashcardModeScreen> {
  final _random = Random();

  CardPool _cardPool = CardPool.all;
  StudyDirection _study = StudyDirection.characterToDefinition;

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
    final List<CharacterEntry> source = switch (_cardPool) {
      CardPool.all => widget.store.activeCharacters,
      CardPool.hard => widget.store.hardCharacters,
      CardPool.favorites =>
        widget.store.activeCharacters.where((c) => c.isStarred).toList(),
    };
    final pool = source
        .where((c) => _charToDef || c.definition.trim().isNotEmpty)
        .toList()
      ..shuffle(_random);
    _pool = pool;
    _index = 0;
    _revealed = false;
    _pickDirection();
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

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard mode'),
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: _goHome,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildToggles(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(child: _buildBody()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The options bar: two matching outlined dropdown pills (which cards,
  /// which direction), the same height and style.
  Widget _buildToggles() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _dropdownPill<CardPool>(
            leading: Icon(_cardPool.icon, size: 20, color: _cardPool.color),
            value: _cardPool,
            options: CardPool.values,
            label: (option) => option.label,
            onChanged: _setCardPool,
          ),
          _dropdownPill<StudyDirection>(
            leading: const Icon(Icons.swap_horiz, size: 20),
            value: _study,
            options: StudyDirection.values,
            label: (option) => option.label,
            onChanged: _setStudy,
          ),
        ],
      ),
    );
  }

  /// One outlined, rounded dropdown with an icon in front.
  Widget _dropdownPill<T>({
    required Widget leading,
    required T value,
    required List<T> options,
    required String Function(T) label,
    required void Function(T) onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.expand_more),
              borderRadius: BorderRadius.circular(12),
              // No blue highlight left on the button after choosing.
              focusColor: Colors.transparent,
              style: labelStyle?.copyWith(color: colors.onSurface),
              items: [
                for (final option in options)
                  DropdownMenuItem<T>(
                    value: option,
                    child: Text(label(option)),
                  ),
              ],
              onChanged: (selected) {
                // Drop keyboard focus so the button isn't left highlighted.
                FocusScope.of(context).unfocus();
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_pool.isEmpty) {
      final message = switch (_cardPool) {
        CardPool.hard =>
          'No hard-flagged characters yet — flag some with the 🔥 button '
              'first.',
        CardPool.favorites =>
          'No favorites yet — star some characters with the ☆ button first.',
        CardPool.all => 'No characters to study yet — add some first.',
      };
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (_cardPool != CardPool.all) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _setCardPool(CardPool.all),
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
                border: Border.all(color: Colors.grey),
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
                        ?.copyWith(color: Colors.grey),
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
          const SizedBox(height: 24),
          if (_revealed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _answer(false),
                  child: const Text('Incorrect'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _answer(true),
                  child: const Text('Correct'),
                ),
              ],
            )
          else
            Text(askingCharacter
                ? 'Tap the card to reveal the character'
                : 'Tap the card to reveal the definition'),
          const SizedBox(height: 24),
          // Opens this card's character screen; Back returns to this same
          // card (2026-09-20). Replaced the old "Back" button. Only shown
          // once the card is revealed, together with Correct/Incorrect, so
          // it can't give the answer away.
          if (_revealed)
            TextButton.icon(
              onPressed: () => _openCharacter(current),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Go to character screen'),
            ),
        ],
      ),
    );
  }

  /// One side of the card. [showCharacter] is true for the character side
  /// (the front in Character → Definition, the answer in Definition →
  /// Character). The character side always shows the typed character and,
  /// if there is one, your drawing.
  Widget _cardFace(CharacterEntry card, {required bool showCharacter}) {
    if (!showCharacter) {
      return Text(
        card.definition.isEmpty ? '(no definition yet)' : card.definition,
        textAlign: TextAlign.center,
      );
    }
    final strokes = card.handwrittenSample;
    final hasDrawing = strokes != null && strokes.isNotEmpty;
    // Typed character plus your drawing underneath, whichever side of the
    // card the character is on (question in Character → Definition, answer
    // in Definition → Character). Since 2026-09-20.
    if (!hasDrawing) {
      return Text(card.typedCharacter, style: const TextStyle(fontSize: 72));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(card.typedCharacter, style: const TextStyle(fontSize: 56)),
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
