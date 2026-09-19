import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'character_entry.dart';
import 'stroke_codec.dart';

// Drift generates this file from the table classes below. It is NOT written
// by hand. Regenerate it after any change to this file with:
//   dart run build_runner build --delete-conflicting-outputs
// (see docs/setup_manual.md). The generated file is committed to git.
part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables
//
// Class names carry a `Db` prefix so they can't collide with Flutter's own
// `Characters` class (from package:characters). `tableName` keeps the real
// SQL table names short and readable. Column getters become snake_case SQL
// columns automatically (e.g. `typedCharacter` -> `typed_character`).
// See docs/decisions_log_sqlite_drift.md for why each table looks this way.
// ---------------------------------------------------------------------------

/// One row per dictionary character. The flashcard counters live here as
/// columns (decision 4: counters only, exactly one set per character).
@DataClassName('CharacterRow')
class DbCharacters extends Table {
  @override
  String get tableName => 'characters';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get typedCharacter => text().withDefault(const Constant('?'))();
  TextColumn get definition => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  BoolColumn get isHard => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Packed handwriting strokes (see [StrokeCodec]); null = not drawn yet.
  BlobColumn get handwriting => blob().nullable()();

  IntColumn get timesSeen => integer().withDefault(const Constant(0))();
  IntColumn get timesCorrect => integer().withDefault(const Constant(0))();
  IntColumn get timesIncorrect => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
}

/// Every distinct tag name, stored once (decision 2).
@DataClassName('TagRow')
class DbTags extends Table {
  @override
  String get tableName => 'tags';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}

/// Which characters carry which tags. `position` keeps the tags in the
/// order they were typed, so they display the same way after a restart.
@DataClassName('CharacterTagRow')
class DbCharacterTags extends Table {
  @override
  String get tableName => 'character_tags';

  IntColumn get characterId => integer()
      .references(DbCharacters, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(DbTags, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {characterId, tagId};
}

/// Undirected links between two characters. Each pair is stored exactly
/// once, always with the smaller id in `character_a_id` (enforced by the
/// CHECK constraint), and both characters see the link.
@DataClassName('CharacterReferenceRow')
class DbCharacterReferences extends Table {
  @override
  String get tableName => 'character_references';

  IntColumn get characterAId => integer()
      .references(DbCharacters, #id, onDelete: KeyAction.cascade)();
  IntColumn get characterBId => integer()
      .references(DbCharacters, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {characterAId, characterBId};

  @override
  List<String> get customConstraints => [
        'CHECK (character_a_id < character_b_id)',
      ];
}

/// Photos of a character seen "out and about" (decision 5). Created now,
/// screens built later. The image itself is a normal file in the app's
/// support folder; this row only stores where that file is.
@DataClassName('CharacterPhotoRow')
class DbCharacterPhotos extends Table {
  @override
  String get tableName => 'character_photos';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get characterId => integer()
      .references(DbCharacters, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime()();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

/// The app's SQLite database. [DictionaryStore] is the only class that
/// talks to it; screens never do.
///
/// The query helpers below take and return plain Dart values so the store
/// doesn't need to know any Drift syntax.
@DriftDatabase(tables: [
  DbCharacters,
  DbTags,
  DbCharacterTags,
  DbCharacterReferences,
  DbCharacterPhotos,
])
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests (e.g. `NativeDatabase.memory()`). With no
  /// argument, opens the real on-device database file.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  /// File name (Drift adds `.sqlite`, so the file is
  /// `cantonese_dictionary.sqlite`).
  static const String fileName = 'cantonese_dictionary';

  /// Name of the visible folder the database goes in on desktop.
  static const String desktopFolderName = 'Cantonese Dictionary';

  static QueryExecutor _openDefault() {
    return driftDatabase(
      name: fileName,
      native: const DriftNativeOptions(
        databaseDirectory: databaseDirectory,
      ),
    );
  }

  /// Where the database file lives:
  /// - **Windows (and other desktops):** a visible, easy-to-find folder,
  ///   `Documents\Cantonese Dictionary\`, so it doesn't get forgotten in a
  ///   hidden system folder like `%APPDATA%`.
  /// - **Android:** the app's private storage. That's the standard place on
  ///   phones; putting it anywhere visible needs extra storage permissions,
  ///   and Android's newer rules restrict it anyway. Getting data *off* the
  ///   phone is the job of the planned backup/export feature (open item 7
  ///   in docs/decisions_log_sqlite_drift.md).
  static Future<Directory> databaseDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return getApplicationSupportDirectory();
    }
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${documents.path}${Platform.pathSeparator}$desktopFolderName');
    await dir.create(recursive: true);
    return dir;
  }

  /// Bump this whenever a table changes, and add a matching step in
  /// [migration]'s `onUpgrade`, so existing installs keep their data.
  @override
  int get schemaVersion => 1;

  /// True if the database file was created fresh during this app run
  /// (first launch). Only meaningful after the first query has run, since
  /// Drift opens the database lazily.
  bool wasCreatedThisRun = false;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          wasCreatedThisRun = true;
        },
        beforeOpen: (details) async {
          // SQLite ignores foreign keys (and so the cascade deletes) unless
          // this is switched on for every connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---- Reads --------------------------------------------------------------

  Future<List<CharacterRow>> allCharacterRows() {
    return (select(dbCharacters)..orderBy([(c) => OrderingTerm.asc(c.id)]))
        .get();
  }

  /// Tag names per character id, in typed order.
  Future<Map<int, List<String>>> tagNamesByCharacter() async {
    final query = select(dbCharacterTags).join([
      innerJoin(dbTags, dbTags.id.equalsExp(dbCharacterTags.tagId)),
    ])
      ..orderBy([
        OrderingTerm.asc(dbCharacterTags.characterId),
        OrderingTerm.asc(dbCharacterTags.position),
      ]);
    final rows = await query.get();
    final result = <int, List<String>>{};
    for (final row in rows) {
      final link = row.readTable(dbCharacterTags);
      final tag = row.readTable(dbTags);
      result.putIfAbsent(link.characterId, () => []).add(tag.name);
    }
    return result;
  }

  /// Every stored reference pair, as `(smallerId, largerId)`.
  Future<List<(int, int)>> allReferencePairs() async {
    final rows = await select(dbCharacterReferences).get();
    return [for (final r in rows) (r.characterAId, r.characterBId)];
  }

  // ---- Writes -------------------------------------------------------------

  /// Inserts a new character (ignoring [entry]'s id) and returns the id
  /// SQLite assigned. Tags are written separately via [replaceTags].
  Future<int> insertCharacter(CharacterEntry entry) {
    return into(dbCharacters).insert(_companionFor(entry));
  }

  /// Overwrites every column of the character row with [entry]'s values.
  Future<void> updateCharacterRow(CharacterEntry entry) async {
    await (update(dbCharacters)..where((c) => c.id.equals(entry.id)))
        .write(_companionFor(entry));
  }

  /// Replaces [characterId]'s tags with [names] (already trimmed and
  /// de-duplicated), creating any tag names that don't exist yet. Tags that
  /// end up used by no character are kept, so a future "pick an existing
  /// tag" list still offers them.
  Future<void> replaceTags(int characterId, List<String> names) {
    return transaction(() async {
      await (delete(dbCharacterTags)
            ..where((t) => t.characterId.equals(characterId)))
          .go();
      for (var i = 0; i < names.length; i++) {
        final tagId = await _tagIdFor(names[i]);
        await into(dbCharacterTags).insert(DbCharacterTagsCompanion.insert(
          characterId: characterId,
          tagId: tagId,
          position: Value(i),
        ));
      }
    });
  }

  Future<int> _tagIdFor(String name) async {
    final existing = await (select(dbTags)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(dbTags).insert(DbTagsCompanion.insert(name: name));
  }

  /// Deletes a character. Its tag links, references and photo rows go with
  /// it automatically (foreign-key cascade); this also deletes the photo
  /// image files themselves, which the database can't do.
  Future<void> deleteCharacter(int id) async {
    final photos = await (select(dbCharacterPhotos)
          ..where((p) => p.characterId.equals(id)))
        .get();
    await (delete(dbCharacters)..where((c) => c.id.equals(id))).go();
    for (final photo in photos) {
      final file = File(photo.filePath);
      if (await file.exists()) await file.delete();
    }
  }

  /// Stores the undirected link a <-> b. No-op if it already exists.
  Future<void> addReferencePair(int a, int b) async {
    final low = a < b ? a : b;
    final high = a < b ? b : a;
    await into(dbCharacterReferences).insert(
      DbCharacterReferencesCompanion.insert(
        characterAId: low,
        characterBId: high,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Removes the undirected link a <-> b, if present.
  Future<void> removeReferencePair(int a, int b) async {
    final low = a < b ? a : b;
    final high = a < b ? b : a;
    await (delete(dbCharacterReferences)
          ..where(
              (r) => r.characterAId.equals(low) & r.characterBId.equals(high)))
        .go();
  }

  DbCharactersCompanion _companionFor(CharacterEntry entry) {
    final stats = entry.flashcardStats;
    return DbCharactersCompanion(
      typedCharacter: Value(entry.typedCharacter),
      definition: Value(entry.definition),
      notes: Value(entry.notes),
      isStarred: Value(entry.isStarred),
      isHard: Value(entry.isHard),
      isArchived: Value(entry.isArchived),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
      handwriting: Value(StrokeCodec.encode(entry.handwrittenSample)),
      timesSeen: Value(stats.timesSeen),
      timesCorrect: Value(stats.timesCorrect),
      timesIncorrect: Value(stats.timesIncorrect),
      lastReviewedAt: Value(stats.lastReviewedAt),
    );
  }
}
