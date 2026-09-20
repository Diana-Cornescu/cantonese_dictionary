import 'dart:io';

import 'package:cantonese_dictionary_app/data/app_database.dart';
import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
// drift.dart is imported with `show` on purpose: it also exports its own
// `isNull`/`isNotNull`, which would clash with flutter_test's matchers.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Tags as a thing in their own right — the Tags screen, 2026-09-20:
// listing them (orphans included), bulk-assigning characters, renaming,
// merging and deleting. `dictionary_store_test.dart` covers tags as a
// property of one character; this file covers the tag list itself.

DictionaryStore _newStore() =>
    DictionaryStore(AppDatabase(NativeDatabase.memory()));

Future<DictionaryStore> _openFileStore(File file) async {
  final store = DictionaryStore(AppDatabase(NativeDatabase(file)));
  await store.load();
  return store;
}

/// Removes the example character the very first [DictionaryStore.load]
/// seeds, and its "example" tag with it, so the assertions below start
/// from an empty dictionary AND an empty tag list. (Deleting a character
/// deliberately leaves its tags behind as orphans, which is exactly what
/// this file is here to test — so the tag has to go explicitly.)
Future<void> _clearSeed(DictionaryStore store) async {
  for (final entry in store.characters.toList()) {
    await store.deleteCharacter(entry.id);
  }
  for (final tag in store.allTags.toList()) {
    await store.deleteTag(tag);
  }
}

CharacterEntry _draft(String typedCharacter, {String tags = ''}) {
  final now = DateTime.now();
  return CharacterEntry(
    id: -1, // ignored by DictionaryStore.addCharacter
    typedCharacter: typedCharacter,
    handwrittenSample: null,
    definition: 'test definition',
    notes: '',
    tags: tags,
    isStarred: false,
    isHard: false,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
    flashcardStats: FlashcardStats.zero,
    referencedCharacterIds: const [],
  );
}

/// The tags of the character with this typed character, in stored order.
List<String> _tagsOf(DictionaryStore store, String typedCharacter) =>
    parseTags(store.characters
        .firstWhere((c) => c.typedCharacter == typedCharacter)
        .tags);

void main() {
  // The reload tests deliberately open AppDatabase more than once.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late DictionaryStore store;
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    store = _newStore();
    tempDir = Directory.systemTemp.createTempSync('cantonese_tag_test_');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}test.sqlite');
  });

  tearDown(() async {
    await store.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('allTags lists every tag once, sorted, with per-tag counts', () async {
    await store.load();
    await _clearSeed(store);
    await store.addCharacter(_draft('食', tags: 'food, verb'));
    await store.addCharacter(_draft('飲', tags: 'Drink, verb'));

    // Sorted case-insensitively, which is how the Tags screen shows them.
    expect(store.allTags, ['Drink', 'food', 'verb']);
    expect(store.tagCount('verb'), 2);
    expect(store.tagCount('food'), 1);
    expect(store.tagCount('nope'), 0);
    expect(
      [for (final c in store.charactersWithTag('verb')) c.typedCharacter],
      ['食', '飲'],
    );
  });

  test('a tag with no characters left is kept, and counts 0', () async {
    await store.load();
    await _clearSeed(store);
    final entry = await store.addCharacter(_draft('食', tags: 'food'));
    await store.updateCharacter(entry.copyWith(tags: ''));

    expect(store.allTags, ['food']);
    expect(store.tagCount('food'), 0);
  });

  test('createTag makes an empty tag and rejects bad or duplicate names',
      () async {
    await store.load();
    await _clearSeed(store);

    expect(await store.createTag('  food  '), isTrue); // trimmed
    expect(store.allTags, ['food']);
    expect(store.tagCount('food'), 0);

    expect(await store.createTag('food'), isFalse); // already there
    expect(await store.createTag('   '), isFalse); // blank
    expect(await store.createTag('a,b'), isFalse); // would split in two
    expect(store.allTags, ['food']);
  });

  test('setTagCharacters both adds and removes, leaving other tags alone',
      () async {
    await store.load();
    await _clearSeed(store);
    await store.addCharacter(_draft('食', tags: 'food'));
    final b = await store.addCharacter(_draft('飲', tags: 'verb'));
    await store.addCharacter(_draft('山'));

    await store.setTagCharacters('food', [b.id]);

    expect(_tagsOf(store, '食'), isEmpty); // removed
    expect(_tagsOf(store, '飲'), ['verb', 'food']); // added, 'verb' kept
    expect(_tagsOf(store, '山'), isEmpty); // untouched
    expect(store.tagCount('food'), 1);
  });

  test('renaming a tag renames it on every character and survives a reload',
      () async {
    final first = await _openFileStore(dbFile);
    await _clearSeed(first);
    await first.addCharacter(_draft('食', tags: 'food, verb'));
    await first.addCharacter(_draft('飲', tags: 'food'));

    expect(await first.renameTag('food', 'eating'), isTrue);
    expect(_tagsOf(first, '食'), ['eating', 'verb']); // position kept
    expect(_tagsOf(first, '飲'), ['eating']);
    expect(first.allTags, ['eating', 'verb']);
    await first.close();

    final second = await _openFileStore(dbFile);
    expect(second.allTags, ['eating', 'verb']);
    expect(_tagsOf(second, '食'), ['eating', 'verb']);
    await second.close();
  });

  test('renaming onto an existing tag merges the two, without duplicates',
      () async {
    await store.load();
    await _clearSeed(store);
    await store.addCharacter(_draft('食', tags: 'food, verb'));
    await store.addCharacter(_draft('飲', tags: 'verb'));

    expect(await store.renameTag('food', 'verb'), isTrue);

    expect(_tagsOf(store, '食'), ['verb']); // not ['verb', 'verb']
    expect(_tagsOf(store, '飲'), ['verb']);
    expect(store.allTags, ['verb']);
    expect(store.tagCount('verb'), 2);
  });

  test('renameTag refuses a blank name or one with a comma', () async {
    await store.load();
    await _clearSeed(store);
    await store.addCharacter(_draft('食', tags: 'food'));

    expect(await store.renameTag('food', '   '), isFalse);
    expect(await store.renameTag('food', 'a,b'), isFalse);
    expect(store.allTags, ['food']);
    expect(_tagsOf(store, '食'), ['food']);
  });

  test('deleting a tag removes it everywhere but keeps the characters',
      () async {
    final first = await _openFileStore(dbFile);
    await _clearSeed(first);
    await first.addCharacter(_draft('食', tags: 'food, verb'));
    await first.addCharacter(_draft('飲', tags: 'food'));

    await first.deleteTag('food');

    expect(first.characters.length, 2);
    expect(_tagsOf(first, '食'), ['verb']);
    expect(_tagsOf(first, '飲'), isEmpty);
    expect(first.allTags, ['verb']);
    await first.close();

    final second = await _openFileStore(dbFile);
    expect(second.allTags, ['verb']);
    expect(second.characters.length, 2);
    await second.close();
  });

  test('isValidTagName rejects what would break the comma-joined string', () {
    expect(isValidTagName('food'), isTrue);
    expect(isValidTagName('  food  '), isTrue);
    expect(isValidTagName(''), isFalse);
    expect(isValidTagName('   '), isFalse);
    expect(isValidTagName('food, verb'), isFalse);
  });
}
