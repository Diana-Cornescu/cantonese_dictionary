import 'dart:io';

import 'package:cantonese_dictionary_app/data/app_database.dart';
import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
// `show` on purpose: drift.dart's own isNull/isNotNull clash with
// flutter_test's matchers.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CharacterEntry _draft(String typedCharacter) {
  final now = DateTime.now();
  return CharacterEntry(
    id: -1,
    typedCharacter: typedCharacter,
    handwrittenSample: null,
    definition: 'def of $typedCharacter',
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
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempDir;
  late File dbFile;
  late Directory photosDir;

  String path(String name) => '${tempDir.path}${Platform.pathSeparator}$name';

  Future<DictionaryStore> open() async {
    final store = DictionaryStore(
      AppDatabase(NativeDatabase(dbFile)),
      photosDirectory: () async => photosDir,
    );
    await store.load();
    return store;
  }

  File sourceImage() =>
      File(path('source.jpg'))..writeAsBytesSync([9, 8, 7, 6]);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('photo_store_test_');
    dbFile = File(path('test.sqlite'));
    photosDir = Directory(path('photos'));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('adding a photo copies the file and links several characters, '
      'and it all survives a reload', () async {
    final first = await open();
    final a = await first.addCharacter(_draft('A'));
    final b = await first.addCharacter(_draft('B'));
    final source = sourceImage();

    final photo = await first.addPhoto(source,
        characterIds: [a.id, b.id], note: '  sign on a shop  ');

    expect(source.existsSync(), isTrue, reason: 'original is untouched');
    final copy = await first.photoFile(photo);
    expect(copy.path, isNot(source.path));
    expect(copy.readAsBytesSync(), [9, 8, 7, 6]);
    expect(photo.note, 'sign on a shop');
    expect(first.photosFor(a.id).single.id, photo.id);
    expect(first.photosFor(b.id).single.id, photo.id);

    await first.close();
    final second = await open();
    final reloaded = second.photos.single;
    expect(reloaded.fileName, photo.fileName);
    expect(reloaded.note, 'sign on a shop');
    expect(reloaded.characterIds.toSet(), {a.id, b.id});
    await second.close();
  });

  test('note and linked characters can be changed', () async {
    final store = await open();
    final a = await store.addCharacter(_draft('A'));
    final b = await store.addCharacter(_draft('B'));
    final photo =
        await store.addPhoto(sourceImage(), characterIds: [a.id]);

    await store.updatePhotoNote(photo.id, 'new note');
    await store.setPhotoCharacters(photo.id, [b.id]);

    await store.close();
    final reopened = await open();
    final p = reopened.photos.single;
    expect(p.note, 'new note');
    expect(p.characterIds, [b.id]);
    expect(reopened.photosFor(a.id), isEmpty);
    await reopened.close();
  });

  test('deleting a character keeps the photo but unlinks it', () async {
    final store = await open();
    final a = await store.addCharacter(_draft('A'));
    final b = await store.addCharacter(_draft('B'));
    final photo =
        await store.addPhoto(sourceImage(), characterIds: [a.id, b.id]);

    await store.deleteCharacter(a.id);
    expect(store.photos.single.characterIds, [b.id]);
    expect((await store.photoFile(photo)).existsSync(), isTrue);

    await store.close();
    final reopened = await open();
    expect(reopened.photos.single.characterIds, [b.id]);
    await reopened.close();
  });

  test('deleting a photo removes its row and its file', () async {
    final store = await open();
    final a = await store.addCharacter(_draft('A'));
    final photo = await store.addPhoto(sourceImage(), characterIds: [a.id]);
    final file = await store.photoFile(photo);

    await store.deletePhoto(photo.id);
    expect(store.photos, isEmpty);
    expect(file.existsSync(), isFalse);

    await store.close();
    final reopened = await open();
    expect(reopened.photos, isEmpty);
    await reopened.close();
  });

  test('a version 1 database is upgraded: old photo rows are kept',
      () async {
    // Build a database exactly as schema version 1 left it, with one
    // character and one row in the old character_photos table.
    final v1 = NativeDatabase(dbFile, setup: (db) {
      db.execute('''
        CREATE TABLE characters (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          typed_character TEXT NOT NULL DEFAULT '?',
          definition TEXT NOT NULL DEFAULT '',
          notes TEXT NOT NULL DEFAULT '',
          is_starred INTEGER NOT NULL DEFAULT 0,
          is_hard INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          handwriting BLOB NULL,
          times_seen INTEGER NOT NULL DEFAULT 0,
          times_correct INTEGER NOT NULL DEFAULT 0,
          times_incorrect INTEGER NOT NULL DEFAULT 0,
          last_reviewed_at TEXT NULL
        )''');
      db.execute('CREATE TABLE tags (id INTEGER NOT NULL PRIMARY KEY '
          'AUTOINCREMENT, name TEXT NOT NULL, UNIQUE(name))');
      db.execute('CREATE TABLE character_tags (character_id INTEGER NOT '
          'NULL, tag_id INTEGER NOT NULL, position INTEGER NOT NULL '
          'DEFAULT 0, PRIMARY KEY (character_id, tag_id))');
      db.execute('CREATE TABLE character_references (character_a_id '
          'INTEGER NOT NULL, character_b_id INTEGER NOT NULL, PRIMARY KEY '
          '(character_a_id, character_b_id))');
      db.execute('CREATE TABLE character_photos (id INTEGER NOT NULL '
          'PRIMARY KEY AUTOINCREMENT, character_id INTEGER NOT NULL, '
          'file_path TEXT NOT NULL, created_at TEXT NOT NULL)');
      db.execute("INSERT INTO characters (id, typed_character, definition, "
          "created_at, updated_at) VALUES (1, 'X', 'old one', "
          "'2026-09-19T10:00:00.000', '2026-09-19T10:00:00.000')");
      db.execute("INSERT INTO character_photos (id, character_id, "
          "file_path, created_at) VALUES (7, 1, 'old.jpg', "
          "'2026-09-19T11:00:00.000')");
      db.execute('PRAGMA user_version = 1');
    });
    final store = DictionaryStore(
      AppDatabase(v1),
      photosDirectory: () async => photosDir,
    );
    await store.load();

    expect(store.characters.single.typedCharacter, 'X');
    final photo = store.photos.single;
    expect(photo.id, 7);
    expect(photo.fileName, 'old.jpg');
    expect(photo.note, '');
    expect(photo.characterIds, [1]);
    await store.close();
  });
}
