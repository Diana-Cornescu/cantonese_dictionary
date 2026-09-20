import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cantonese_dictionary_app/data/app_database.dart';
import 'package:cantonese_dictionary_app/data/backup_service.dart';
import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
// `show` on purpose: drift.dart's own isNull/isNotNull clash with
// flutter_test's matchers.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CharacterEntry _draft(String typedCharacter, {String tags = ''}) {
  final now = DateTime.now();
  return CharacterEntry(
    id: -1,
    typedCharacter: typedCharacter,
    handwrittenSample: [
      [const StrokePoint(x: 1, y: 2, t: 1000)],
    ],
    definition: 'def of $typedCharacter',
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

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempDir;
  late File dbFile;
  late DictionaryStore store;
  late BackupService backups;

  String path(String name) => '${tempDir.path}${Platform.pathSeparator}$name';

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('backup_service_test_');
    dbFile = File(path('cantonese_dictionary.sqlite'));
    store = DictionaryStore(
      AppDatabase(NativeDatabase(dbFile)),
      reopen: () => AppDatabase(NativeDatabase(dbFile)),
    );
    await store.load();
    backups = BackupService(
      store: store,
      databaseFile: dbFile,
      photosDirectory: Directory(path('photos')),
      safetyDirectory: Directory(path('safety_backups')),
      tempDirectory: Directory(path('tmp')),
    );
  });

  tearDown(() async {
    await store.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('backup then restore brings the old data back', () async {
    final kept = await store.addCharacter(_draft('K', tags: 'food, verb'));
    final backup = await backups.createBackup();
    expect(backup.suggestedName, startsWith('cantonese_dictionary_backup_'));
    expect(backup.suggestedName, endsWith('.zip'));
    expect(backups.inspect(backup.bytes), 2); // seeded example + K

    // Change things after the backup.
    await store.deleteCharacter(kept.id);
    await store.addCharacter(_draft('L'));
    expect(store.characters.any((c) => c.typedCharacter == 'K'), isFalse);

    final restoredCount = await backups.restore(backup.bytes);

    expect(restoredCount, 2);
    final restoredK =
        store.characters.firstWhere((c) => c.typedCharacter == 'K');
    expect(restoredK.tags, 'food, verb');
    expect(restoredK.handwrittenSample!.single.single.t, 1000);
    expect(store.characters.any((c) => c.typedCharacter == 'L'), isFalse);

    // A safety copy of the pre-restore data (which had L) was saved.
    expect(await backups.latestSafetyCopy(), isNotNull);
  });

  test('undo last restore brings back the data from before the restore',
      () async {
    final backup = await backups.createBackup(); // example only
    await store.addCharacter(_draft('M'));
    await backups.restore(backup.bytes);
    expect(store.characters.any((c) => c.typedCharacter == 'M'), isFalse);

    await backups.undoLastRestore();
    expect(store.characters.any((c) => c.typedCharacter == 'M'), isTrue);
  });

  test('rejects a file that is not a backup, and changes nothing', () async {
    await store.addCharacter(_draft('N'));
    final junk = Uint8List.fromList(utf8.encode('definitely not a zip'));

    expect(() => backups.inspect(junk), throwsA(isA<BackupException>()));
    await expectLater(
        backups.restore(junk), throwsA(isA<BackupException>()));
    expect(store.characters.any((c) => c.typedCharacter == 'N'), isTrue);
    expect(await backups.latestSafetyCopy(), isNull);
  });

  test('rejects a backup made by a newer app version', () async {
    final info = utf8.encode(jsonEncode({
      'format': BackupService.formatName,
      'formatVersion': BackupService.formatVersion,
      'schemaVersion': AppDatabase.currentSchemaVersion + 1,
      'characterCount': 0,
    }));
    final fakeDb = utf8.encode('SQLite format 3\u0000rest');
    final archive = Archive()
      ..addFile(ArchiveFile('backup_info.json', info.length, info))
      ..addFile(ArchiveFile('database.sqlite', fakeDb.length, fakeDb));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    expect(
      () => backups.inspect(bytes),
      throwsA(isA<BackupException>().having(
          (e) => e.message, 'message', contains('newer version'))),
    );
  });
}
