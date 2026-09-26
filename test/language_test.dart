import 'dart:io';

import 'package:cantonese_dictionary_app/data/app_database.dart';
import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/dictionary_store.dart';
import 'package:cantonese_dictionary_app/widgets/language_filter_options.dart';
import 'package:cantonese_dictionary_app/widgets/list_filter_button.dart';
// See dictionary_store_test.dart for why drift.dart is imported with `show`.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The optional Language field (schema version 4, 2026-09-26).

CharacterEntry _draft(
  String typedCharacter, {
  bool cantonese = false,
  bool mandarin = false,
}) {
  final now = DateTime.now();
  return CharacterEntry(
    id: -1,
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
    isCantonese: cantonese,
    isMandarin: mandarin,
  );
}

Future<DictionaryStore> _openFileStore(File file) async {
  final store = DictionaryStore(AppDatabase(NativeDatabase(file)));
  await store.load();
  return store;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cantonese_language_test_');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}test.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('storage', () {
    test('a new character is "not set" unless a language is chosen',
        () async {
      final store = await _openFileStore(dbFile);
      final plain = await store.addCharacter(_draft('A'));
      expect(plain.isCantonese, isFalse);
      expect(plain.isMandarin, isFalse);
      expect(plain.hasLanguage, isFalse);
      await store.close();
    });

    test('languages are saved, toggled and survive a reload', () async {
      final first = await _openFileStore(dbFile);
      final both =
          await first.addCharacter(_draft('B', cantonese: true, mandarin: true));
      final c = await first.addCharacter(_draft('C'));
      await first.toggleMandarin(c.id);
      await first.toggleCantonese(both.id); // both -> Mandarin only

      await first.close();
      final second = await _openFileStore(dbFile);
      final rb = second.characters.firstWhere((e) => e.id == both.id);
      final rc = second.characters.firstWhere((e) => e.id == c.id);
      expect(rb.isCantonese, isFalse);
      expect(rb.isMandarin, isTrue);
      expect(rc.isCantonese, isFalse);
      expect(rc.isMandarin, isTrue);

      // Editing something else leaves the language alone.
      await second.updateCharacter(rc.copyWith(definition: 'edited'));
      expect(
          second.characters.firstWhere((e) => e.id == c.id).isMandarin, isTrue);
      await second.close();
    });

    test('a version 3 database is upgraded and keeps its characters',
        () async {
      // Build a database, then turn it back into a version 3 one: drop the
      // two new columns and set the version number back.
      final first = await _openFileStore(dbFile);
      final kept = await first.addCharacter(_draft('D'));
      await first.close();

      final raw = AppDatabase(NativeDatabase(dbFile));
      await raw
          .customStatement('ALTER TABLE characters DROP COLUMN is_cantonese');
      await raw
          .customStatement('ALTER TABLE characters DROP COLUMN is_mandarin');
      await raw.customStatement('PRAGMA user_version = 3');
      await raw.close();

      final upgraded = await _openFileStore(dbFile);
      final d = upgraded.characters.firstWhere((e) => e.id == kept.id);
      expect(d.typedCharacter, 'D');
      expect(d.hasLanguage, isFalse);
      await upgraded.toggleCantonese(d.id);
      expect(upgraded.characters.firstWhere((e) => e.id == d.id).isCantonese,
          isTrue);
      await upgraded.close();
    });
  });

  group('filters', () {
    final cantonese = _draft('粵', cantonese: true);
    final mandarin = _draft('普', mandarin: true);
    final both = _draft('共', cantonese: true, mandarin: true);
    final unset = _draft('?');
    final all = [cantonese, mandarin, both, unset];

    List<String> pick(bool Function(CharacterEntry) test) =>
        [for (final c in all.where(test)) c.typedCharacter];

    test('LanguageFilter boxes (Flashcards, Write): a card is in if it '
        'matches any checked box', () {
      bool Function(CharacterEntry) boxes(Set<LanguageFilter> checked) =>
          (c) => LanguageFilter.anyMatch(checked, c);

      // The default: all three checked, nothing left out.
      expect(pick(boxes(LanguageFilter.all)), ['粵', '普', '共', '?']);
      // Words marked both stay in while either language is checked.
      expect(pick(boxes({LanguageFilter.cantonese})), ['粵', '共']);
      expect(pick(boxes({LanguageFilter.mandarin})), ['普', '共']);
      expect(pick(boxes({LanguageFilter.notSet})), ['?']);
      expect(
          pick(boxes({LanguageFilter.cantonese, LanguageFilter.mandarin})),
          ['粵', '普', '共']);
      expect(
          pick(boxes({LanguageFilter.mandarin, LanguageFilter.notSet})),
          ['普', '共', '?']);
      expect(pick(boxes({})), isEmpty);
    });

    test('filter sheet toggles combine with AND', () {
      ListFilters on(Set<String> ids) => ListFilters(on: ids);
      bool Function(CharacterEntry) sheet(Set<String> ids) =>
          (c) => LanguageFilterOptions.matches(on(ids), c);

      expect(pick(sheet({})), ['粵', '普', '共', '?']);
      expect(pick(sheet({LanguageFilterOptions.cantonese})), ['粵', '共']);
      expect(pick(sheet({LanguageFilterOptions.mandarin})), ['普', '共']);
      expect(
          pick(sheet({
            LanguageFilterOptions.cantonese,
            LanguageFilterOptions.mandarin,
          })),
          ['共']);
      expect(pick(sheet({LanguageFilterOptions.notSet})), ['?']);
    });

    test('Not set and Cantonese / Mandarin switch each other off', () {
      const none = ListFilters();
      const cantoneseOn =
          ListFilters(on: {LanguageFilterOptions.cantonese});

      // Not set turned on: Cantonese goes off. Other toggles are kept.
      final notSet = LanguageFilterOptions.enforceLanguageRule(
        const ListFilters(on: {
          LanguageFilterOptions.cantonese,
          LanguageFilterOptions.notSet,
          'favorites',
        }),
        const ListFilters(on: {LanguageFilterOptions.cantonese, 'favorites'}),
      );
      expect(notSet.on, {LanguageFilterOptions.notSet, 'favorites'});

      // Mandarin turned on: Not set goes off.
      final mandarin = LanguageFilterOptions.enforceLanguageRule(
        const ListFilters(on: {
          LanguageFilterOptions.notSet,
          LanguageFilterOptions.mandarin,
        }),
        const ListFilters(on: {LanguageFilterOptions.notSet}),
      );
      expect(mandarin.on, {LanguageFilterOptions.mandarin});

      // Cantonese + Mandarin together is allowed.
      final both = LanguageFilterOptions.enforceLanguageRule(
        const ListFilters(on: {
          LanguageFilterOptions.cantonese,
          LanguageFilterOptions.mandarin,
        }),
        cantoneseOn,
      );
      expect(both.on,
          {LanguageFilterOptions.cantonese, LanguageFilterOptions.mandarin});

      // Nothing to enforce.
      expect(LanguageFilterOptions.enforceLanguageRule(none, none).on, isEmpty);
    });
  });
}
