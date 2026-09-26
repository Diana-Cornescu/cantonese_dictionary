import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'app_database.dart';
import 'character_entry.dart';
import 'photo_entry.dart';
import 'stroke_codec.dart';

/// Central store for all dictionary data. Screens read from its in-memory
/// list; every change is written to the SQLite database ([AppDatabase])
/// first and only then applied in memory, so memory never shows something
/// that failed to save. This is a [ChangeNotifier]: widgets should read
/// from it with `ListenableBuilder`/`AnimatedBuilder`.
///
/// "Storage swap only" (decision 6 in
/// `docs/decisions_log_sqlite_drift.md`): the public API below is exactly
/// what it was when this class was backed by a JSON file, so no screen had
/// to change.
///
/// This is the ONLY place that is allowed to mutate [CharacterEntry] data.
/// Screens are expected to treat everything below as a stable public API:
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
  /// [reopen] creates a fresh [AppDatabase] on the same file. It's only
  /// needed for [replaceDatabase] (restoring a backup).
  /// [photosDirectory] says where photo files live; it defaults to the real
  /// app folder and is only overridden in tests.
  DictionaryStore(
    this._db, {
    AppDatabase Function()? reopen,
    Future<Directory> Function()? photosDirectory,
  })  : _reopen = reopen,
        _photosDirectoryResolver =
            photosDirectory ?? AppDatabase.photosDirectory;

  AppDatabase _db;
  final AppDatabase Function()? _reopen;
  final Future<Directory> Function() _photosDirectoryResolver;
  Directory? _photosDir;
  final List<PhotoEntry> _photos = [];
  final Map<String, String> _settings = {};
  final List<CharacterEntry> _characters = [];
  /// Every tag name the database knows, orphans included. Kept in step with
  /// the `tags` table so the Tags screen can list tags nobody uses.
  final List<String> _tagNames = [];
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

  /// Every tag name the app knows, including tags that no character
  /// carries right now (an "orphan", e.g. after its last character was
  /// deleted or untagged). Sorted case-insensitively, which is how the
  /// Tags screen lists them.
  List<String> get allTags {
    final names = [..._tagNames];
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List.unmodifiable(names);
  }

  /// Characters carrying [tag] (exact match, archived ones included).
  List<CharacterEntry> charactersWithTag(String tag) => List.unmodifiable(
      _characters.where((c) => parseTags(c.tags).contains(tag)));

  /// How many characters carry [tag]. 0 means it's an orphan tag.
  int tagCount(String tag) => charactersWithTag(tag).length;

  /// Characters flagged hard, excluding archived ones. Archiving is treated
  /// as "put away", so an archived-and-hard character drops out of this
  /// study shortlist until it's unarchived again.
  List<CharacterEntry> get hardCharacters => List.unmodifiable(
      _characters.where((c) => c.isHard && !c.isArchived));

  /// Loads everything from the database into memory, seeding exactly one
  /// example character the very first time the database is created. Safe
  /// to call once at app startup; must complete before any other method is
  /// called.
  Future<void> load() async {
    final rows = await _db.allCharacterRows();
    final tagsById = await _db.tagNamesByCharacter();
    final allTagNames = await _db.allTagNames();
    final pairs = await _db.allReferencePairs();
    final photoRows = await _db.allPhotoRows();
    final photoLinks = await _db.allPhotoLinks();
    final settings = await _db.allSettings();

    final refsById = <int, List<int>>{};
    for (final (a, b) in pairs) {
      refsById.putIfAbsent(a, () => []).add(b);
      refsById.putIfAbsent(b, () => []).add(a);
    }

    _characters
      ..clear()
      ..addAll(rows.map((row) => _entryFromRow(
            row,
            tags: tagsById[row.id] ?? const [],
            references: refsById[row.id] ?? const [],
          )));

    _tagNames
      ..clear()
      ..addAll(allTagNames);

    _settings
      ..clear()
      ..addAll(settings);

    final linksByPhoto = <int, List<int>>{};
    for (final (photoId, characterId) in photoLinks) {
      linksByPhoto.putIfAbsent(photoId, () => []).add(characterId);
    }
    _photos
      ..clear()
      ..addAll(photoRows.map((row) => PhotoEntry(
            id: row.id,
            fileName: row.fileName,
            note: row.note,
            createdAt: row.createdAt,
            characterIds: linksByPhoto[row.id] ?? const [],
          )));

    // Checked after the first query on purpose: Drift opens (and, on first
    // launch, creates) the database lazily on that first query.
    if (_db.wasCreatedThisRun && _characters.isEmpty) {
      await addCharacter(_exampleCharacter(), notify: false);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Closes the database connection. Only needed in tests.
  Future<void> close() => _db.close();

  /// Writes a complete copy of the database to [path]. Used by backups.
  Future<void> snapshotDatabaseTo(String path) => _db.copyTo(path);

  /// File names of all stored photos. Used by backups.
  Future<List<String>> photoFileNames() async =>
      [for (final p in _photos) p.fileName];

  /// Closes the database, runs [swapFiles] (which replaces the database
  /// file on disk, e.g. with a restored backup), then reopens it and
  /// reloads everything. Screens refresh automatically afterwards.
  Future<void> replaceDatabase(Future<void> Function() swapFiles) async {
    final reopen = _reopen;
    if (reopen == null) {
      throw StateError('DictionaryStore was created without `reopen`.');
    }
    await _db.close();
    try {
      await swapFiles();
    } finally {
      _db = reopen();
      await load();
    }
  }

  CharacterEntry _entryFromRow(
    CharacterRow row, {
    required List<String> tags,
    required List<int> references,
  }) {
    return CharacterEntry(
      id: row.id,
      typedCharacter: row.typedCharacter,
      handwrittenSample: StrokeCodec.decode(row.handwriting),
      definition: row.definition,
      notes: row.notes,
      tags: tags.join(', '),
      isStarred: row.isStarred,
      isHard: row.isHard,
      isArchived: row.isArchived,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      flashcardStats: FlashcardStats(
        timesSeen: row.timesSeen,
        timesCorrect: row.timesCorrect,
        timesIncorrect: row.timesIncorrect,
        lastReviewedAt: row.lastReviewedAt,
      ),
      referencedCharacterIds: List<int>.of(references),
      isCantonese: row.isCantonese,
      isMandarin: row.isMandarin,
    );
  }

  CharacterEntry _exampleCharacter() {
    final now = DateTime.now();
    return CharacterEntry(
      id: -1, // replaced by the id the database assigns
      typedCharacter: '愛',
      handwrittenSample: null,
      definition: 'This is an example row — tap it to see how the detail '
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
    );
  }

  /// Writes [entry]'s own row (not tags or references) to the database,
  /// then swaps it into the in-memory list. The list position is looked up
  /// again after the write, in case another change landed in between.
  Future<void> _saveRow(CharacterEntry entry) async {
    await _db.updateCharacterRow(entry);
    final index = _indexOf(entry.id);
    if (index == -1) return;
    _characters[index] = entry;
    notifyListeners();
  }

  int _indexOf(int id) => _characters.indexWhere((c) => c.id == id);

  /// Adds [draft] as a brand new character. Its `id`, `createdAt`,
  /// `updatedAt` and `referencedCharacterIds` are ignored/reset (a new
  /// character always starts with no references — use [addReference]
  /// afterwards) and replaced with freshly assigned values. Returns the
  /// entry actually stored, including its real id.
  Future<CharacterEntry> addCharacter(
    CharacterEntry draft, {
    bool notify = true,
  }) async {
    final now = DateTime.now();
    final tagNames = parseTags(draft.tags);
    final pending = draft.copyWith(
      createdAt: now,
      updatedAt: now,
      tags: tagNames.join(', '),
      referencedCharacterIds: const [],
    );
    final id = await _db.transaction(() async {
      final newId = await _db.insertCharacter(pending);
      await _db.replaceTags(newId, tagNames);
      return newId;
    });
    final entry = pending.copyWith(id: id);
    _characters.add(entry);
    _rememberTags(tagNames);
    if (notify) notifyListeners();
    return entry;
  }

  /// Replaces the stored character sharing [updated]'s id with [updated],
  /// bumping `updatedAt` to now. `referencedCharacterIds` on [updated] is
  /// always ignored in favor of whatever is currently stored, since that
  /// field may only change via [addReference]/[removeReference]. No-op if
  /// no character with that id exists.
  ///
  /// `createdAt` on [updated] is ignored too: it's the "date added" shown
  /// on the character screen, set once by [addCharacter] and never
  /// editable afterwards (1.6.0).
  Future<void> updateCharacter(CharacterEntry updated) async {
    final index = _indexOf(updated.id);
    if (index == -1) return;
    final existing = _characters[index];
    final tagNames = parseTags(updated.tags);
    final entry = updated.copyWith(
      tags: tagNames.join(', '),
      referencedCharacterIds: existing.referencedCharacterIds,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _db.transaction(() async {
      await _db.updateCharacterRow(entry);
      if (entry.tags != existing.tags) {
        await _db.replaceTags(entry.id, tagNames);
      }
    });
    final newIndex = _indexOf(entry.id);
    if (newIndex == -1) return;
    _characters[newIndex] = entry;
    _rememberTags(tagNames);
    notifyListeners();
  }

  /// Deletes the character with id [id] and scrubs it out of every other
  /// character's `referencedCharacterIds`, so no dangling ids remain.
  /// No-op if no character with that id exists.
  Future<void> deleteCharacter(int id) async {
    if (_indexOf(id) == -1) return;
    // The database removes the character's tag links, references and photo
    // rows itself (cascade); the loop below mirrors that in memory.
    await _db.deleteCharacter(id);
    _characters.removeWhere((c) => c.id == id);
    // Photos stay, but no longer point at the deleted character.
    for (var i = 0; i < _photos.length; i++) {
      final photo = _photos[i];
      if (photo.characterIds.contains(id)) {
        _photos[i] = photo.copyWith(
          characterIds: photo.characterIds.where((c) => c != id).toList(),
        );
      }
    }
    for (var i = 0; i < _characters.length; i++) {
      final entry = _characters[i];
      if (entry.referencedCharacterIds.contains(id)) {
        _characters[i] = entry.copyWith(
          referencedCharacterIds:
              entry.referencedCharacterIds.where((r) => r != id).toList(),
        );
      }
    }
    notifyListeners();
  }

  /// Flips `isStarred` on character [id]. No-op if it doesn't exist.
  Future<void> toggleStarred(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    await _saveRow(
        c.copyWith(isStarred: !c.isStarred, updatedAt: DateTime.now()));
  }

  /// Flips `isHard` on character [id]. No-op if it doesn't exist.
  Future<void> toggleHard(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    await _saveRow(
        c.copyWith(isHard: !c.isHard, updatedAt: DateTime.now()));
  }

  /// Flips `isArchived` on character [id]. No-op if it doesn't exist.
  Future<void> toggleArchived(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    await _saveRow(
        c.copyWith(isArchived: !c.isArchived, updatedAt: DateTime.now()));
  }

  /// Turns the Cantonese label on character [id] on or off. Independent of
  /// Mandarin: both on means the word is shared. The character screen
  /// asks for confirmation before calling this. No-op if the character
  /// doesn't exist.
  Future<void> toggleCantonese(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    await _saveRow(
        c.copyWith(isCantonese: !c.isCantonese, updatedAt: DateTime.now()));
  }

  /// Turns the Mandarin label on character [id] on or off. See
  /// [toggleCantonese].
  Future<void> toggleMandarin(int id) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    await _saveRow(
        c.copyWith(isMandarin: !c.isMandarin, updatedAt: DateTime.now()));
  }

  /// Records one flashcard review outcome for [id]: always increments
  /// `timesSeen`, plus either `timesCorrect` or `timesIncorrect`, and sets
  /// `lastReviewedAt` to now. No-op if no character with that id exists.
  Future<void> recordReview(int id, {required bool correct}) async {
    final index = _indexOf(id);
    if (index == -1) return;
    final c = _characters[index];
    final stats = c.flashcardStats;
    final now = DateTime.now();
    await _saveRow(c.copyWith(
      flashcardStats: stats.copyWith(
        timesSeen: stats.timesSeen + 1,
        timesCorrect: correct ? stats.timesCorrect + 1 : null,
        timesIncorrect: correct ? null : stats.timesIncorrect + 1,
        lastReviewedAt: now,
      ),
      updatedAt: now,
    ));
  }

  /// Adds a symmetric/undirected reference between two characters: [idB]
  /// is inserted into [idA]'s `referencedCharacterIds` and [idA] into
  /// [idB]'s, in one operation. No-op if either id doesn't exist, if
  /// they're equal, or if the reference already exists on both sides.
  Future<void> addReference(int idA, int idB) async {
    if (idA == idB) return;
    if (_indexOf(idA) == -1 || _indexOf(idB) == -1) return;
    await _db.addReferencePair(idA, idB);
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
    notifyListeners();
  }

  /// Removes a symmetric/undirected reference between two characters,
  /// undoing both sides of what [addReference] did. No-op (per side) if
  /// that id doesn't exist or the reference wasn't present.
  Future<void> removeReference(int idA, int idB) async {
    if (idA == idB) return;
    await _db.removeReferencePair(idA, idB);
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
    notifyListeners();
  }

  // ---- Photos ---------------------------------------------------------------

  // ---- Tags ---------------------------------------------------------------
  //
  // Added 2026-09-20 with the Tags screen.
  //
  // A character's tags exist twice: as the `tags`/`character_tags` rows
  // (linked by tag ID) and as `CharacterEntry.tags`, one comma-separated
  // string keyed by NAME. The string is NOT a column on the characters
  // table — `load` rebuilds it from the tag tables — so it is a display
  // copy, not storage. Both must always agree.
  //
  // That shapes the split below. Editing a character's own tag list goes
  // through [updateCharacter], the single writer that keeps string and rows
  // in step. Editing the TAG (rename, delete) does not: it changes no
  // column on any character, so it does its work on the tag rows and then
  // refreshes the display copies with [_rewriteTagsInMemory]. Pushing those
  // through [updateCharacter] would write nothing but a new `updatedAt`,
  // marking characters as edited that nobody edited (fixed 2026-09-20).

  /// Notes tag names that a character write may just have created, so
  /// [allTags] lists them without a reload.
  void _rememberTags(Iterable<String> names) {
    for (final name in names) {
      if (!_tagNames.contains(name)) _tagNames.add(name);
    }
  }

  /// Applies [change] to every character's tag list IN MEMORY ONLY, to
  /// bring the display copies back in line with tag rows the caller has
  /// already changed in the database.
  ///
  /// Characters whose list is unaffected are left alone, so their
  /// `updatedAt` is untouched. The caller notifies.
  void _rewriteTagsInMemory(List<String> Function(List<String> names) change) {
    for (var i = 0; i < _characters.length; i++) {
      final entry = _characters[i];
      final next = change(parseTags(entry.tags)).join(', ');
      if (next == entry.tags) continue;
      _characters[i] = entry.copyWith(tags: next);
    }
  }

  /// Creates [name] as an empty tag, carried by no character yet.
  ///
  /// Returns false (changing nothing) if the name isn't usable or a tag
  /// with that exact name already exists.
  Future<bool> createTag(String name) async {
    final clean = name.trim();
    if (!isValidTagName(clean)) return false;
    if (_tagNames.contains(clean)) return false;
    await _db.ensureTag(clean);
    _tagNames.add(clean);
    notifyListeners();
    return true;
  }

  /// Replaces the set of characters carrying [tag]: every id in
  /// [characterIds] gets it (appended at the end of its tag list), and
  /// every character that has it but isn't listed loses it.
  ///
  /// The tag itself is kept even when the result is that nobody carries
  /// it, so it stays pickable.
  ///
  /// Unlike [renameTag] and [deleteTag], this DOES go through
  /// [updateCharacter] and so bumps `updatedAt`: adding or removing a tag
  /// changes what those characters are tagged with, which is an edit to
  /// them, not to the tag.
  Future<void> setTagCharacters(String tag, List<int> characterIds) async {
    if (!isValidTagName(tag)) return;
    final wanted = characterIds.toSet();
    await _db.ensureTag(tag);
    _rememberTags([tag]);
    // Iterated over a copy: updateCharacter replaces entries in _characters.
    for (final entry in [..._characters]) {
      final names = parseTags(entry.tags);
      final has = names.contains(tag);
      final should = wanted.contains(entry.id);
      if (has == should) continue;
      final next = should
          ? [...names, tag]
          : names.where((t) => t != tag).toList();
      await updateCharacter(entry.copyWith(tags: next.join(', ')));
    }
    notifyListeners();
  }

  /// Renames [from] to [to] on every character that carries it.
  ///
  /// If a tag called [to] already exists the two are MERGED: characters
  /// that had either end up with [to] once, and [from] is gone. Returns
  /// false (changing nothing) if [to] isn't a usable tag name.
  ///
  /// No character's `updatedAt` moves: renaming a tag relabels it, it
  /// doesn't edit the characters wearing it.
  Future<bool> renameTag(String from, String to) async {
    final clean = to.trim();
    if (!isValidTagName(clean)) return false;
    if (clean == from) return true;
    if (!_tagNames.contains(from)) return false;

    /// [from] swapped for [clean] in one character's tag list, keeping the
    /// order and collapsing the duplicate a merge can create.
    List<String> renamed(List<String> names) {
      final next = <String>[];
      for (final name in names) {
        final replaced = name == from ? clean : name;
        if (!next.contains(replaced)) next.add(replaced);
      }
      return next;
    }

    if (_tagNames.contains(clean)) {
      // Merging. Two rows have to become one, so the links really do move:
      // each affected character is re-linked to the surviving row, and only
      // then can the emptied row go.
      for (final entry in [..._characters]) {
        final names = parseTags(entry.tags);
        if (!names.contains(from)) continue;
        await _db.replaceTags(entry.id, renamed(names));
      }
      await _db.deleteTagByName(from);
    } else {
      // Nothing to merge with, so nothing moves. The row keeps its id and
      // every link to it; only its name changes. One statement.
      await _db.renameTagRow(from, clean);
    }

    _rewriteTagsInMemory(renamed);
    _tagNames.remove(from);
    _rememberTags([clean]);
    notifyListeners();
    return true;
  }

  /// Removes [tag] from every character and forgets the tag itself.
  /// The characters are kept, of course, and their `updatedAt` doesn't
  /// move — deleting a tag is an edit to the tag.
  Future<void> deleteTag(String tag) async {
    // One statement: deleteTagByName drops the tag's links along with its
    // row, so there is nothing to write per character.
    await _db.deleteTagByName(tag);
    _rewriteTagsInMemory((names) => names.where((t) => t != tag).toList());
    _tagNames.remove(tag);
    notifyListeners();
  }

  /// All photos, newest first.
  List<PhotoEntry> get photos => List.unmodifiable(_photos);

  /// Photos linked to character [characterId], newest first.
  List<PhotoEntry> photosFor(int characterId) => List.unmodifiable(
      _photos.where((p) => p.characterIds.contains(characterId)));

  /// The folder photo files live in (created if missing).
  Future<Directory> photosDirectory() async {
    final dir = _photosDir ??= await _photosDirectoryResolver();
    await dir.create(recursive: true);
    return dir;
  }

  /// The image file for [photo].
  Future<File> photoFile(PhotoEntry photo) async {
    final dir = await photosDirectory();
    return File('${dir.path}${Platform.pathSeparator}${photo.fileName}');
  }

  /// Copies [source] into the app's photos folder (the original is left
  /// untouched) and links it to [characterIds]. Returns the new photo.
  Future<PhotoEntry> addPhoto(
    File source, {
    List<int> characterIds = const [],
    String note = '',
  }) async {
    final dir = await photosDirectory();
    final now = DateTime.now();
    final dot = source.path.lastIndexOf('.');
    final ext = dot == -1 ? '.jpg' : source.path.substring(dot).toLowerCase();
    final fileName =
        '${now.millisecondsSinceEpoch}_${Random().nextInt(1000000)}$ext';
    final copy =
        await source.copy('${dir.path}${Platform.pathSeparator}$fileName');
    final int id;
    try {
      id = await _db.insertPhoto(
        fileName: fileName,
        note: note.trim(),
        createdAt: now,
        characterIds: characterIds,
      );
    } catch (_) {
      if (await copy.exists()) await copy.delete();
      rethrow;
    }
    final photo = PhotoEntry(
      id: id,
      fileName: fileName,
      note: note.trim(),
      createdAt: now,
      characterIds: characterIds.toSet().toList(),
    );
    _photos.insert(0, photo);
    notifyListeners();
    return photo;
  }

  /// Changes [photoId]'s note (empty = no note).
  Future<void> updatePhotoNote(int photoId, String note) async {
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index == -1) return;
    await _db.updatePhotoNote(photoId, note.trim());
    _photos[index] = _photos[index].copyWith(note: note.trim());
    notifyListeners();
  }

  /// Replaces which characters [photoId] is linked to.
  Future<void> setPhotoCharacters(int photoId, List<int> characterIds) async {
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index == -1) return;
    final ids = characterIds.toSet().toList();
    await _db.setPhotoLinks(photoId, ids);
    _photos[index] = _photos[index].copyWith(characterIds: ids);
    notifyListeners();
  }

  /// Deletes a photo and its image file.
  Future<void> deletePhoto(int photoId) async {
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index == -1) return;
    final photo = _photos[index];
    await _db.deletePhotoRow(photoId);
    _photos.removeAt(index);
    final file = await photoFile(photo);
    if (await file.exists()) await file.delete();
    notifyListeners();
  }

  // ---- Settings -------------------------------------------------------------

  /// A stored setting, or null if never set.
  String? setting(String key) => _settings[key];

  /// Saves a setting (kept in the database, so it's included in backups).
  Future<void> setSetting(String key, String value) async {
    await _db.putSetting(key, value);
    _settings[key] = value;
    notifyListeners();
  }
}
