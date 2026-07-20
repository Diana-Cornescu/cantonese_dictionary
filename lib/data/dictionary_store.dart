import 'dart:async';

import 'package:flutter/foundation.dart';

import 'character_entry.dart';
import 'storage_service.dart';

/// Central in-memory store for all dictionary data, backed by a single
/// JSON file on disk via [StorageService]. This is a [ChangeNotifier]:
/// widgets should read from it with `ListenableBuilder`/`AnimatedBuilder`.
///
/// This is the ONLY place that is allowed to mutate [CharacterEntry] data.
/// Phase 2 UI screens (list, detail, add, flashcard, export) are expected
/// to treat everything below as a stable public API:
///   - read with [characters] / [activeCharacters] / [archivedCharacters] /
///     [hardCharacters]
///   - write only through the methods on this class, never by constructing
///     a modified [CharacterEntry] and poking it into the list yourself.
///
/// In particular, `referencedCharacterIds` must only ever change via
/// [addReference] / [removeReference]: this class actively enforces that
/// (see [updateCharacter]) rather than merely documenting it, so the two
/// sides of a reference can never drift out of sync.
class DictionaryStore extends ChangeNotifier {
  DictionaryStore(this._storage);

  final StorageService _storage;
  final List<CharacterEntry> _characters = [];
  int _nextId = 1;
  bool _isLoaded = false;

  /// Whether [load] has completed at least once.
  bool get isLoaded => _isLoaded;

  /// All characters, including archived ones, in storage order.
  List<CharacterEntry> get characters => List.unmodifiable(_characters);

  /// Characters that are not archived.
  List<CharacterEntry> get activeCharacters =>
      List.unmodifiable(_characters.where((c) => !c.isArchived));

  /// Archived characters only.
  List<CharacterEntry> get archivedCharacters =>
      List.unmodifiable(_characters.where((c) => c.isArchived));

  /// Characters flagged hard, excluding archived ones. Archiving is treated
  /// as "put away", so an archived-and-hard character drops out of this
  /// study shortlist until it's unarchived again.
  List<CharacterEntry> get hardCharacters => List.unmodifiable(
      _characters.where((c) => c.isHard && !c.isArchived));

  /// Loads from disk, seeding exactly one example character if no JSON
  /// file exists yet (first run). Safe to call once at app startup; must
  /// complete before any other method is called.
  Future<void> load() async {
    final raw = await _storage.readJson();
    _characters.clear();
    if (raw == null) {
      _nextId = 1;
      _seedExampleCharacter();
      await _save();
    } else {
      _nextId = (raw['nextId'] as num?)?.toInt() ?? 1;
      final rawList = raw['characters'] as List<dynamic>? ?? const [];
      _characters.addAll(
        rawList.map((e) => CharacterEntry.fromJson(e as Map<String, dynamic>)),
      );
    }
    _isLoaded = true;
    notifyListeners();
  }

  void _seedExampleCharacter() {
    final now = DateTime.now();
    _characters.add(CharacterEntry(
      id: _nextId++,
      typedCharacter: '愛',
      handwrittenSample: null,
      definition: "This is an example row — tap it to see how the detail "
          'screen works, star or hard-flag it to try the shortlists, or '
          "delete it once you're comfortable. (Cantonese: oi3, meaning "
          "'love'.)",
      notes: "Delete this row whenever you're ready — it's just here to "
          'show the layout.',
      tags: 'example',
      isStarred: true,
      isHard: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      flashcardStats: FlashcardStats.zero,
      referencedCharacterIds: const [],
    ));
  }

  Future<void> _save() {
    return _storage.writeJson({
      'nextId': _nextId,
      'characters': _characters.map((c) => c.toJson()).toList(),
    });
  }

  int _indexOf(int id) => _characters.indexWhere((c) => c.id == id);

  /// Adds [draft] as a brand new character. Its `id`, `createdAt`,
  /// `updatedAt` and `referencedCharacterIds` are ignored/reset (a new
  /// character always starts with no references — use [addReference]
  /// afterwards) and replaced with freshly assigned values. Returns the
  /// entry actually stored, including its real id.
  Future<CharacterEntry> addCharacter(CharacterEntry draft) async {
    final now = DateTime.now();
    final entry = draft.copyWith(
      id: _nextId++,
      createdAt: now,
      updatedAt: now,
      referencedCharacterIds: const [],
    );
    _characters.add(entry);
    await _save();
    notifyListeners();
    return entry;
  }

  /// Replaces the stored character sharing [updated]'s id with [updated],
  /// bumping `updatedAt` to now. `referencedCharacterIds` on [updated] is
  /// always ignored in favor of whatever is currently stored, since that
  /// field may only change via [addReference]/[removeReference]. No-op if
  /// no character with that id exists.
  Future<void> updateCharacter(CharacterEntry updated) async {
    final index = _indexOf(updated.id);
    if (index == -1) return;
    final existing = _characters[index];
    _characters[index] = updated.copyWith(
      referencedCharacterIds: existing.referencedCharacterIds,
      updatedAt: DateTime.now(),
    );
    await _save();
    notifyListeners();
  }

  /// Deletes the character with id [id] and scrubs it out of every other
  /// character's `referencedCharacterIds`, so no dangling ids remain.
  /// No-op if no character with that id exists.
  Future<void> deleteCharacter(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    _characters.removeAt(index);
    for (var i = 0; i < _characters.length; i++) {
      final entry = _characters[i];
      if (entry.referencedCharacterIds.contains(id)) {
        _characters[i] = entry.copyWith(
          referencedCharacterIds:
              entry.referencedCharacterIds.where((r) => r != id).toList(),
        );
      }
    }
    await _save();
    notifyListeners();
  }

  /// Flips `isStarred` on character [id]. No-op if it doesn't exist.
  Future<void> toggleStarred(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    _characters[index] =
        c.copyWith(isStarred: !c.isStarred, updatedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  /// Flips `isHard` on character [id]. No-op if it doesn't exist.
  Future<void> toggleHard(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    _characters[index] =
        c.copyWith(isHard: !c.isHard, updatedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  /// Flips `isArchived` on character [id]. No-op if it doesn't exist.
  Future<void> toggleArchived(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    _characters[index] =
        c.copyWith(isArchived: !c.isArchived, updatedAt: DateTime.now());
    await _save();
    notifyListeners();
  }

  /// Records one flashcard review outcome for [id]: always increments
  /// `timesSeen`, plus either `timesCorrect` or `timesIncorrect`, and sets
  /// `lastReviewedAt` to now. No-op if no character with that id exists.
  Future<void> recordReview(int id, {required bool correct}) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    final stats = c.flashcardStats;
    _characters[index] = c.copyWith(
      flashcardStats: stats.copyWith(
        timesSeen: stats.timesSeen + 1,
        timesCorrect: correct ? stats.timesCorrect + 1 : null,
        timesIncorrect: correct ? null : stats.timesIncorrect + 1,
        lastReviewedAt: DateTime.now(),
      ),
      updatedAt: DateTime.now(),
    );
    await _save();
    notifyListeners();
  }

  /// Adds a symmetric/undirected reference between two characters: [idB]
  /// is inserted into [idA]'s `referencedCharacterIds` and [idA] into
  /// [idB]'s, in one operation. No-op if either id doesn't exist, if
  /// they're equal, or if the reference already exists on both sides.
  Future<void> addReference(int idA, int idB) async {
    if (idA == idB) return;
    final indexA = _indexOf(idA);
    final indexB = _indexOf(idB);
    if (indexA == -1 || indexB == -1) return;
    final a = _characters[indexA];
    final b = _characters[indexB];
    if (!a.referencedCharacterIds.contains(idB)) {
      _characters[indexA] = a.copyWith(
        referencedCharacterIds: [...a.referencedCharacterIds, idB],
      );
    }
    if (!b.referencedCharacterIds.contains(idA)) {
      _characters[indexB] = b.copyWith(
        referencedCharacterIds: [...b.referencedCharacterIds, idA],
      );
    }
    await _save();
    notifyListeners();
  }

  /// Removes a symmetric/undirected reference between two characters,
  /// undoing both sides of what [addReference] did. No-op (per side) if
  /// that id doesn't exist or the reference wasn't present.
  Future<void> removeReference(int idA, int idB) async {
    if (idA == idB) return;
    final indexA = _indexOf(idA);
    final indexB = _indexOf(idB);
    if (indexA != -1) {
      final a = _characters[indexA];
      _characters[indexA] = a.copyWith(
        referencedCharacterIds:
            a.referencedCharacterIds.where((r) => r != idB).toList(),
      );
    }
    if (indexB != -1) {
      final b = _characters[indexB];
      _characters[indexB] = b.copyWith(
        referencedCharacterIds:
            b.referencedCharacterIds.where((r) => r != idA).toList(),
      );
    }
    await _save();
    notifyListeners();
  }
}
