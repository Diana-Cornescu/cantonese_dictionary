import 'dart:async';
import 'dart:io';

import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
import 'package:cantonese_dictionary_app/data/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [DictionaryStore] backed by a fresh file inside [tempDir].
/// Never touches real app data or `path_provider`.
DictionaryStore _newStoreIn(Directory tempDir) {
  final file = File('${tempDir.path}${Platform.pathSeparator}test_data.json');
  return DictionaryStore(StorageService(file));
}

/// A minimal draft character for tests that don't care about most fields.
CharacterEntry _draft(String typedCharacter) {
  final now = DateTime.now();
  return CharacterEntry(
    id: -1, // ignored by DictionaryStore.addCharacter
    typedCharacter: typedCharacter,
    handwrittenSample: null,
    definition: 'test definition',
    notes: '',
    tags: '',
    isStarred: false,
    isHard: false,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
    flashcardStats: FlashcardStats.zero,
    referencedCharacterIds: const [],
  );
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cantonese_dictionary_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('loading with no existing file seeds exactly one example character',
      () async {
    final store = _newStoreIn(tempDir);
    await store.load();

    expect(store.characters.length, 1);
    final seeded = store.characters.single;
    expect(seeded.typedCharacter, '愛');
    expect(seeded.flashcardStats, FlashcardStats.zero);
    expect(seeded.flashcardStats.timesSeen, 0);
    expect(seeded.flashcardStats.timesCorrect, 0);
    expect(seeded.flashcardStats.timesIncorrect, 0);
    expect(seeded.flashcardStats.lastReviewedAt, isNull);
  });

  test('addReference is symmetric and removeReference undoes both sides',
      () async {
    final store = _newStoreIn(tempDir);
    await store.load();

    final a = await store.addCharacter(_draft('A'));
    final b = await store.addCharacter(_draft('B'));

    await store.addReference(a.id, b.id);
    var updatedA = store.characters.firstWhere((c) => c.id == a.id);
    var updatedB = store.characters.firstWhere((c) => c.id == b.id);
    expect(updatedA.referencedCharacterIds, contains(b.id));
    expect(updatedB.referencedCharacterIds, contains(a.id));

    await store.removeReference(a.id, b.id);
    updatedA = store.characters.firstWhere((c) => c.id == a.id);
    updatedB = store.characters.firstWhere((c) => c.id == b.id);
    expect(updatedA.referencedCharacterIds, isNot(contains(b.id)));
    expect(updatedB.referencedCharacterIds, isNot(contains(a.id)));
  });

  test('recordReview increments the right counters and sets lastReviewedAt',
      () async {
    final store = _newStoreIn(tempDir);
    await store.load();
    final entry = await store.addCharacter(_draft('C'));

    await store.recordReview(entry.id, correct: true);
    var updated = store.characters.firstWhere((c) => c.id == entry.id);
    expect(updated.flashcardStats.timesSeen, 1);
    expect(updated.flashcardStats.timesCorrect, 1);
    expect(updated.flashcardStats.timesIncorrect, 0);
    expect(updated.flashcardStats.lastReviewedAt, isNotNull);

    await store.recordReview(entry.id, correct: false);
    updated = store.characters.firstWhere((c) => c.id == entry.id);
    expect(updated.flashcardStats.timesSeen, 2);
    expect(updated.flashcardStats.timesCorrect, 1);
    expect(updated.flashcardStats.timesIncorrect, 1);
  });

  test(
      'archiving excludes from activeCharacters but not the full list; '
      'deleting removes it and scrubs references', () async {
    final store = _newStoreIn(tempDir);
    await store.load();
    final a = await store.addCharacter(_draft('D'));
    final b = await store.addCharacter(_draft('E'));
    await store.addReference(a.id, b.id);

    await store.toggleArchived(a.id);
    expect(store.characters.any((c) => c.id == a.id), isTrue);
    expect(store.activeCharacters.any((c) => c.id == a.id), isFalse);
    expect(store.archivedCharacters.any((c) => c.id == a.id), isTrue);

    await store.deleteCharacter(a.id);
    expect(store.characters.any((c) => c.id == a.id), isFalse);
    final remainingB = store.characters.firstWhere((c) => c.id == b.id);
    expect(remainingB.referencedCharacterIds, isNot(contains(a.id)));
  });
}
