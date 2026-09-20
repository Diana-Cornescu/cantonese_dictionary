import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/handwriting_canvas.dart';

/// Which way a single card is asked.
enum CardDirection {
  /// Front: typed character. Back: definition.
  characterToDefinition,

  /// Front: definition. Back: typed character + your drawing.
  definitionToCharacter,
}

/// Flashcard practice (redesigned 2026-09-20, see docs/decisions_log.md).
///
/// Three toggle boxes at the top:
///  - **Hard only**: practise only hard-flagged characters.
///  - **Character → Definition** and **Definition → Character**: which way
///    cards are asked. With both on, each card randomly picks one of the
///    two. At least one must stay on.
///
/// Every time the screen opens it starts with only Character → Definition
/// on (Hard only off). Changing any box reshuffles and starts from the top.
/// Both directions add to the same seen/correct/incorrect stats.
class FlashcardModeScreen extends StatefulWidget {
  const FlashcardModeScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<FlashcardModeScreen> createState() => _FlashcardModeScreenState();
}

class _FlashcardModeScreenState extends State<FlashcardModeScreen> {
  final _random = Random();

  bool _hardOnly = false;
  bool _charToDef = true;
  bool _defToChar = false;

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
    final source = _hardOnly
        ? widget.store.hardCharacters
        : widget.store.activeCharacters;
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

  void _toggleHardOnly() {
    setState(() {
      _hardOnly = !_hardOnly;
      _rebuildPool();
    });
  }

  void _toggleDirection(CardDirection which) {
    final turningOff = which == CardDirection.characterToDefinition
        ? _charToDef
        : _defToChar;
    final otherOn = which == CardDirection.characterToDefinition
        ? _defToChar
        : _charToDef;
    if (turningOff && !otherOn) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Keep at least one direction on.')));
      return;
    }
    setState(() {
      if (which == CardDirection.characterToDefinition) {
        _charToDef = !_charToDef;
      } else {
        _defToChar = !_defToChar;
      }
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

  /// The three rounded toggle boxes.
  Widget _buildToggles() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('Hard only'),
            selected: _hardOnly,
            onSelected: (_) => _toggleHardOnly(),
          ),
          FilterChip(
            label: const Text('Character → Definition'),
            selected: _charToDef,
            onSelected: (_) =>
                _toggleDirection(CardDirection.characterToDefinition),
          ),
          FilterChip(
            label: const Text('Definition → Character'),
            selected: _defToChar,
            onSelected: (_) =>
                _toggleDirection(CardDirection.definitionToCharacter),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_pool.isEmpty) {
      final message = _hardOnly
          ? 'No hard-flagged characters yet — flag some with the ! button '
              'first.'
          : 'No characters to study yet — add some first.';
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (_hardOnly) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _toggleHardOnly,
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  /// One side of the card. [showCharacter] is true for the character side
  /// (the front in Character → Definition, the answer in Definition →
  /// Character).
  Widget _cardFace(CharacterEntry card, {required bool showCharacter}) {
    if (!showCharacter) {
      return Text(
        card.definition.isEmpty ? '(no definition yet)' : card.definition,
        textAlign: TextAlign.center,
      );
    }
    final answerSide = _direction == CardDirection.definitionToCharacter;
    final strokes = card.handwrittenSample;
    final hasDrawing = strokes != null && strokes.isNotEmpty;
    // As the question: just the big typed character (as before).
    // As the answer: typed character plus your drawing underneath.
    if (!answerSide || !hasDrawing) {
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
