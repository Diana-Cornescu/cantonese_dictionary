import 'dart:io';

import 'package:cantonese_dictionary_app/data/app_database.dart';
import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
// drift.dart is imported with `show` on purpose: it also exports its own
// `isNull`/`isNotNull`, which would clash with flutter_test's matchers.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [DictionaryStore] backed by a brand-new, empty in-memory SQLite
/// database. Never touches real app data or `path_provider`.
DictionaryStore _newStore() {
  return DictionaryStore(AppDatabase(NativeDatabase.memory()));
}

/// Opens (and loads) a store on a real SQLite file. Used by the "survives
/// a reload" tests: close one store, open a new one on the same file, and
/// check the data came back from disk rather than from memory.
Future<DictionaryStore> _openFileStore(File file) async {
  final store = DictionaryStore(AppDatabase(NativeDatabase(file)));
  await store.load();
  return store;
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
  // The reload tests deliberately open AppDatabase more than once.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late DictionaryStore store;
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    store = _newStore();
    tempDir = Directory.systemTemp.createTempSync('cantonese_dictionary_test_');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}test.sqlite');
  });

  tearDown(() async {
    await store.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('loading a brand-new database seeds exactly one example character',
      () async {
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

  test('tags are stored in the tag tables and survive a reload', () async {
    final first = await _openFileStore(dbFile);
    final added = await first.addCharacter(
      _draft('F').copyWith(tags: ' food,verb, food ,, '),
    );
    // Normalized on save: trimmed, empties dropped, duplicates removed.
    expect(added.tags, 'food, verb');

    await first.updateCharacter(added.copyWith(tags: 'verb, slang'));

    // Close, then reopen the same file: forces a real read from SQLite.
    await first.close();
    final second = await _openFileStore(dbFile);
    final reloaded = second.characters.firstWhere((c) => c.id == added.id);
    expect(reloaded.tags, 'verb, slang');
    await second.close();
  });

  test('handwriting, flags, stats and references survive a reload',
      () async {
    final first = await _openFileStore(dbFile);
    final a = await first.addCharacter(_draft('G').copyWith(
      handwrittenSample: [
        [
          const StrokePoint(x: 1.5, y: 2.25, t: 1000),
          const StrokePoint(x: 3, y: 4, t: 1016),
        ],
        [const StrokePoint(x: 10, y: 20, t: 1200)],
      ],
    ));
    final b = await first.addCharacter(_draft('H'));
    await first.toggleStarred(a.id);
    await first.recordReview(a.id, correct: true);
    await first.addReference(a.id, b.id);

    await first.close();
    final second = await _openFileStore(dbFile);
    final ra = second.characters.firstWhere((c) => c.id == a.id);
    final rb = second.characters.firstWhere((c) => c.id == b.id);
    expect(ra.isStarred, isTrue);
    expect(ra.flashcardStats.timesCorrect, 1);
    expect(ra.referencedCharacterIds, [b.id]);
    expect(rb.referencedCharacterIds, [a.id]);
    final strokes = ra.handwrittenSample!;
    expect(strokes.length, 2);
    expect(strokes[0][1].x, 3);
    expect(strokes[0][1].y, 4);
    expect(strokes[0][1].t, 1016);
    expect(strokes[1][0].t, 1200);
    await second.close();
  });

  test('the example character is only seeded on first creation', () async {
    final first = await _openFileStore(dbFile);
    await first.deleteCharacter(first.characters.single.id);

    await first.close();
    final second = await _openFileStore(dbFile);
    expect(second.characters, isEmpty);
    await second.close();
  });

  test('deleting a character removes its links from the database too',
      () async {
    final first = await _openFileStore(dbFile);
    final a = await first.addCharacter(_draft('I').copyWith(tags: 'x'));
    final b = await first.addCharacter(_draft('J'));
    await first.addReference(a.id, b.id);
    await first.deleteCharacter(a.id);

    await first.close();
    final second = await _openFileStore(dbFile);
    expect(second.characters.any((c) => c.id == a.id), isFalse);
    final rb = second.characters.firstWhere((c) => c.id == b.id);
    expect(rb.referencedCharacterIds, isEmpty);
    await second.close();
  });
}
