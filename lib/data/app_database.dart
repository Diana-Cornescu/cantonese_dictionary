import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'character_entry.dart';
import 'stroke_codec.dart';

// Drift generates this file from the table classes below. It is NOT written
// by hand. Regenerate it after any change to this file with:
//   dart run build_runner build
// (see docs/setup_manual.md). The generated file is committed to git.
part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables
//
// Class names carry a `Db` prefix so they can't collide with Flutter's own
// `Characters` class (from package:characters). `tableName` keeps the real
// SQL table names short and readable. Column getters become snake_case SQL
// columns automatically (e.g. `typedCharacter` -> `typed_character`).
//
// Foreign keys are written as plain SQL in `customConstraints` rather than
// with Drift's `.references(...)`: with the drift_dev version in use,
// `.references(DbCharacters, ...)` produced "This parameter should be a
// simple class name" warnings (2026-09-19), so it wasn't certain the
// constraint was generated. [AppDatabase.deleteCharacter] also deletes the
// linked rows explicitly, so deleting works even without the cascade.
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

  /// Which language the word belongs to (schema version 4). Both can be on
  /// (a word shared by Cantonese and Mandarin), and both off means "not
  /// set" — the field is optional. Two flags rather than one text column,
  /// so "show Cantonese words" is simply `is_cantonese = 1` and naturally
  /// includes the shared ones. Declared last because the v3 -> v4
  /// migration appends them to the end of existing tables, and a fresh
  /// install should come out the same shape.
  BoolColumn get isCantonese => boolean().withDefault(const Constant(false))();
  BoolColumn get isMandarin => boolean().withDefault(const Constant(false))();
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

  IntColumn get characterId => integer()();
  IntColumn get tagId => integer()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {characterId, tagId};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (character_id) REFERENCES characters (id) '
            'ON DELETE CASCADE',
        'FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE',
      ];
}

/// Undirected links between two characters. Each pair is stored exactly
/// once, always with the smaller id in `character_a_id` (enforced by the
/// CHECK constraint), and both characters see the link.
@DataClassName('CharacterReferenceRow')
class DbCharacterReferences extends Table {
  @override
  String get tableName => 'character_references';

  IntColumn get characterAId => integer()();
  IntColumn get characterBId => integer()();

  @override
  Set<Column> get primaryKey => {characterAId, characterBId};

  @override
  List<String> get customConstraints => [
        'CHECK (character_a_id < character_b_id)',
        'FOREIGN KEY (character_a_id) REFERENCES characters (id) '
            'ON DELETE CASCADE',
        'FOREIGN KEY (character_b_id) REFERENCES characters (id) '
            'ON DELETE CASCADE',
      ];
}

/// Photos of characters seen "out and about" (schema version 2, see
/// docs/decisions_log_photo_gallery.md). The image itself is a normal file
/// in [AppDatabase.photosDirectory]; this row only stores its **file
/// name** (not a full path), so photos still resolve after a backup is
/// restored on a different device. Which characters a photo shows is in
/// [DbPhotoCharacters], since one photo can show several characters.
@DataClassName('PhotoRow')
class DbPhotos extends Table {
  @override
  String get tableName => 'photos';

  IntColumn get id => integer().autoIncrement()();

  /// File name inside [AppDatabase.photosDirectory], e.g.
  /// `1789879146039_48213.jpg`.
  TextColumn get fileName => text()();

  /// Optional note, e.g. where the photo was taken.
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Links photos to the characters they show (many-to-many).
@DataClassName('PhotoCharacterRow')
class DbPhotoCharacters extends Table {
  @override
  String get tableName => 'photo_characters';

  IntColumn get photoId => integer()();
  IntColumn get characterId => integer()();

  @override
  Set<Column> get primaryKey => {photoId, characterId};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE',
        'FOREIGN KEY (character_id) REFERENCES characters (id) '
            'ON DELETE CASCADE',
      ];
}

/// Simple app settings as key/value text (schema version 3), e.g. the
/// chosen color theme. Kept in the database so settings travel with
/// backups.
@DataClassName('AppSettingRow')
class DbAppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
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
  DbPhotos,
  DbPhotoCharacters,
  DbAppSettings,
])
class AppDatabase extends _$AppDatabase {
  /// Pass an [executor] in tests (e.g. `NativeDatabase.memory()`). With no
  /// argument, opens the real on-device database file.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  /// File name (Drift adds `.sqlite`, so the file is
  /// `cantonese_dictionary.sqlite`).
  static const String fileName = 'cantonese_dictionary';

  /// Folder inside the project (repo) where the database lives when the
  /// app runs on the development laptop. Git-ignored.
  static const String repoDataFolderName = 'local_data';

  /// Fallback folder (inside Documents) for a desktop build that is run
  /// from somewhere the project folder can't be found.
  static const String desktopFallbackFolderName = 'Cantonese Dictionary';

  static QueryExecutor _openDefault() {
    return driftDatabase(
      name: fileName,
      native: const DriftNativeOptions(
        databaseDirectory: databaseDirectory,
      ),
    );
  }

  /// Where the database file lives:
  /// - **Windows (and other desktops):** inside the project folder, in
  ///   `local_data/` next to `pubspec.yaml`, so it sits with the code and
  ///   is easy to find. The folder is git-ignored, so the database is never
  ///   committed by accident.
  ///   If the project folder can't be found (e.g. a release .exe copied
  ///   somewhere else), it falls back to `Documents\Cantonese Dictionary\`.
  /// - **Android:** the app's private storage. The phone has no copy of the
  ///   project, and private storage is the standard place for app data
  ///   there. Getting data *off* the phone is the job of the planned
  ///   backup/export feature (open item 7 in
  ///   docs/decisions_log_sqlite_drift.md).
  static Future<Directory> databaseDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return getApplicationSupportDirectory();
    }
    final projectRoot = _findProjectRoot();
    final Directory dir;
    if (projectRoot != null) {
      dir = Directory(
          '${projectRoot.path}${Platform.pathSeparator}$repoDataFolderName');
    } else {
      final documents = await getApplicationDocumentsDirectory();
      dir = Directory('${documents.path}${Platform.pathSeparator}'
          '$desktopFallbackFolderName');
    }
    await dir.create(recursive: true);
    return dir;
  }

  /// Finds this project's folder by walking up from where the app was
  /// started, and from where its .exe lives (e.g.
  /// `build\windows\x64\runner\Debug\`), looking for this app's
  /// `pubspec.yaml`. Returns null if not found.
  static Directory? _findProjectRoot() {
    final starts = [
      Directory.current,
      File(Platform.resolvedExecutable).parent,
    ];
    for (final start in starts) {
      Directory dir = start.absolute;
      while (true) {
        final pubspec =
            File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
        if (pubspec.existsSync() &&
            pubspec
                .readAsStringSync()
                .contains('name: cantonese_dictionary_app')) {
          return dir;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break; // reached the drive root
        dir = parent;
      }
    }
    return null;
  }

  /// Bump this whenever a table changes, and add a matching step in
  /// [migration]'s `onUpgrade`, so existing installs keep their data.
  @override
  int get schemaVersion => currentSchemaVersion;

  /// The schema version this build of the app creates and understands.
  /// Also written into backups, so a backup from a newer app version can
  /// be refused instead of half-loaded.
  ///
  /// History:
  ///  - 1 (2026-09-19): characters, tags, character_tags,
  ///    character_references, character_photos.
  ///  - 2 (2026-09-20): character_photos replaced by photos +
  ///    photo_characters (one photo can show several characters, and has
  ///    an optional note).
  ///  - 3 (2026-09-20): app_settings (key/value), e.g. the color theme.
  ///  - 4 (2026-09-26): characters.is_cantonese and characters.is_mandarin
  ///    (the optional Language field). Existing characters start with
  ///    both off, i.e. "not set".
  static const int currentSchemaVersion = 4;

  /// The actual database file used by the real app (not tests).
  static Future<File> databaseFile() async {
    final dir = await databaseDirectory();
    return File('${dir.path}${Platform.pathSeparator}$fileName.sqlite');
  }

  /// Folder holding character photo files (decision 5), next to the
  /// database.
  static Future<Directory> photosDirectory() async {
    final dir = await databaseDirectory();
    return Directory('${dir.path}${Platform.pathSeparator}photos');
  }

  /// Folder for the automatic "before restore" safety copies.
  static Future<Directory> safetyBackupsDirectory() async {
    final dir = await databaseDirectory();
    return Directory('${dir.path}${Platform.pathSeparator}safety_backups');
  }

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
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 -> v2: move any rows from the old one-photo-one-character
            // table into the new photos + photo_characters tables, then
            // drop the old table. (In practice it was always empty: no
            // screen could add photos in v1.)
            await m.createTable(dbPhotos);
            await m.createTable(dbPhotoCharacters);
            await customStatement(
                'INSERT INTO photos (id, file_name, note, created_at) '
                "SELECT id, file_path, '', created_at FROM character_photos");
            await customStatement(
                'INSERT INTO photo_characters (photo_id, character_id) '
                'SELECT id, character_id FROM character_photos');
            await customStatement('DROP TABLE IF EXISTS character_photos');
          }
          if (from < 3) {
            // v2 -> v3: new settings table; nothing to copy.
            await m.createTable(dbAppSettings);
          }
          if (from < 4) {
            // v3 -> v4: the Language flags. Both default to false, so
            // every existing character comes out "not set".
            await m.addColumn(dbCharacters, dbCharacters.isCantonese);
            await m.addColumn(dbCharacters, dbCharacters.isMandarin);
          }
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

  // ---- Tags ---------------------------------------------------------------
  //
  // Added 2026-09-20 for the Tags screen. Tags were already stored in their
  // own table (decision 2), but nothing ever read the table as a whole:
  // [tagNamesByCharacter] only returns tags that some character carries.
  // The methods below let the app see and edit the tag list itself,
  // including tags no character uses ("orphans"), which [replaceTags]
  // deliberately leaves behind.

  /// Every tag name in the database, orphans included, in insertion order.
  Future<List<String>> allTagNames() async {
    final rows = await (select(dbTags)..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return [for (final r in rows) r.name];
  }

  /// Creates [name] if no tag with that exact name exists. Returns its id.
  /// Used to make an empty tag from the Tags screen.
  Future<int> ensureTag(String name) => _tagIdFor(name);

  /// Renames the tag row [from] to [to], keeping its id (and therefore all
  /// its character links).
  ///
  /// `name` is UNIQUE, so this only works when no tag is called [to] yet;
  /// merging two tags is done by moving the characters over and then
  /// calling [deleteTagByName] on the empty one. [DictionaryStore.renameTag]
  /// picks between the two.
  Future<void> renameTagRow(String from, String to) async {
    await (update(dbTags)..where((t) => t.name.equals(from)))
        .write(DbTagsCompanion(name: Value(to)));
  }

  /// Deletes the tag [name] and every character link to it. No-op if no
  /// such tag exists.
  Future<void> deleteTagByName(String name) async {
    await transaction(() async {
      final row = await (select(dbTags)..where((t) => t.name.equals(name)))
          .getSingleOrNull();
      if (row == null) return;
      await (delete(dbCharacterTags)..where((t) => t.tagId.equals(row.id)))
          .go();
      await (delete(dbTags)..where((t) => t.id.equals(row.id))).go();
    });
  }

  /// Deletes a character, together with its tag links, references and
  /// photo links. The photos themselves are kept (they may show other
  /// characters, and stay visible in the gallery); delete a photo
  /// explicitly with [deletePhoto].
  Future<void> deleteCharacter(int id) async {
    await transaction(() async {
      // Linked rows are removed explicitly (not only via the foreign-key
      // cascade), so nothing is left pointing at a deleted character.
      await (delete(dbCharacterTags)..where((t) => t.characterId.equals(id)))
          .go();
      await (delete(dbCharacterReferences)
            ..where((r) =>
                r.characterAId.equals(id) | r.characterBId.equals(id)))
          .go();
      await (delete(dbPhotoCharacters)
            ..where((p) => p.characterId.equals(id)))
          .go();
      await (delete(dbCharacters)..where((c) => c.id.equals(id))).go();
    });
  }

  /// Writes a clean, self-contained copy of the whole database to [path]
  /// (SQLite's `VACUUM INTO`). Safe to run while the app is using the
  /// database. Used by backups.
  Future<void> copyTo(String path) async {
    final escaped = path.replaceAll("'", "''");
    await customStatement("VACUUM INTO '$escaped'");
  }

  // ---- Settings -----------------------------------------------------------

  /// Every stored setting as key -> value.
  Future<Map<String, String>> allSettings() async {
    final rows = await select(dbAppSettings).get();
    return {for (final r in rows) r.settingKey: r.settingValue};
  }

  /// Saves (inserts or replaces) one setting.
  Future<void> putSetting(String key, String value) async {
    await into(dbAppSettings).insertOnConflictUpdate(
      DbAppSettingsCompanion.insert(settingKey: key, settingValue: value),
    );
  }

  // ---- Photos -------------------------------------------------------------

  /// Every photo, newest first.
  Future<List<PhotoRow>> allPhotoRows() {
    return (select(dbPhotos)
          ..orderBy([
            (p) => OrderingTerm.desc(p.createdAt),
            (p) => OrderingTerm.desc(p.id),
          ]))
        .get();
  }

  /// Every photo link, as `(photoId, characterId)`.
  Future<List<(int, int)>> allPhotoLinks() async {
    final rows = await select(dbPhotoCharacters).get();
    return [for (final r in rows) (r.photoId, r.characterId)];
  }

  /// Adds a photo row and links it to [characterIds]. Returns its id.
  Future<int> insertPhoto({
    required String fileName,
    required String note,
    required DateTime createdAt,
    required List<int> characterIds,
  }) {
    return transaction(() async {
      final id = await into(dbPhotos).insert(DbPhotosCompanion.insert(
        fileName: fileName,
        note: Value(note),
        createdAt: createdAt,
      ));
      await _writePhotoLinks(id, characterIds);
      return id;
    });
  }

  Future<void> updatePhotoNote(int photoId, String note) async {
    await (update(dbPhotos)..where((p) => p.id.equals(photoId)))
        .write(DbPhotosCompanion(note: Value(note)));
  }

  /// Replaces which characters [photoId] is linked to.
  Future<void> setPhotoLinks(int photoId, List<int> characterIds) {
    return transaction(() async {
      await (delete(dbPhotoCharacters)..where((p) => p.photoId.equals(photoId)))
          .go();
      await _writePhotoLinks(photoId, characterIds);
    });
  }

  Future<void> _writePhotoLinks(int photoId, List<int> characterIds) async {
    for (final characterId in characterIds.toSet()) {
      await into(dbPhotoCharacters).insert(
        DbPhotoCharactersCompanion.insert(
          photoId: photoId,
          characterId: characterId,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Deletes a photo row and its links (not the image file; the store
  /// does that).
  Future<void> deletePhotoRow(int photoId) {
    return transaction(() async {
      await (delete(dbPhotoCharacters)..where((p) => p.photoId.equals(photoId)))
          .go();
      await (delete(dbPhotos)..where((p) => p.id.equals(photoId))).go();
    });
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
      isCantonese: Value(entry.isCantonese),
      isMandarin: Value(entry.isMandarin),
    );
  }
}
