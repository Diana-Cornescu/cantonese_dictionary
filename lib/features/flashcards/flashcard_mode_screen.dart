import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/character_entry.dart';
import '../../data/dictionary_store.dart';
import '../../theme/app_colors.dart';

/// Flashcard practice: a "Hard" toggle at the top switches the pool between
/// all active characters (the default, on every fresh entry into this
/// screen) and only hard-flagged ones. No intermediate mode-selection
/// screen — practice starts immediately with the default pool, and flipping
/// the toggle reshuffles into the other pool right away.
class FlashcardModeScreen extends StatefulWidget {
  const FlashcardModeScreen({super.key, required this.store});

  final DictionaryStore store;

  @override
  State<FlashcardModeScreen> createState() => _FlashcardModeScreenState();
}

class _FlashcardModeScreenState extends State<FlashcardModeScreen> {
  bool _hardMode = false;
  List<CharacterEntry> _pool = [];
  int _index = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    final pool = List<CharacterEntry>.of(widget.store.activeCharacters);
    pool.shuffle(Random());
    _pool = pool;
  }

  void _setHardMode(bool value) {
    final pool = value
        ? List<CharacterEntry>.of(widget.store.hardCharacters)
        : List<CharacterEntry>.of(widget.store.activeCharacters);
    pool.shuffle(Random());
    setState(() {
      _hardMode = value;
      _pool = pool;
      _index = 0;
      _revealed = false;
    });
  }

  void _next() {
    setState(() {
      _index++;
      if (_index >= _pool.length) {
        _pool = List<CharacterEntry>.of(_pool)..shuffle(Random());
        _index = 0;
      }
      _revealed = false;
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
          const Text('Hard'),
          Switch(
            value: _hardMode,
            onChanged: _setHardMode,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: _goHome,
          ),
        ],
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_pool.isEmpty) {
      final message = _hardMode
          ? 'No hard-flagged characters yet — flag some with the ! button first.'
          : 'No characters to study yet — add some first.';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (_hardMode) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _setHardMode(false),
              child: const Text('Show all characters instead'),
            ),
          ],
        ],
      );
    }
    final current = _pool[_index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${_index + 1} / ${_pool.length}'),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _revealed = !_revealed),
          child: Container(
            width: 280,
            height: 280,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _revealed
                ? Text(
                    current.definition.isEmpty
                        ? '(no definition yet)'
                        : current.definition,
                    textAlign: TextAlign.center,
                  )
                : Text(
                    current.typedCharacter,
                    style: const TextStyle(fontSize: 72),
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
          const Text('Tap the card to reveal the definition'),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
