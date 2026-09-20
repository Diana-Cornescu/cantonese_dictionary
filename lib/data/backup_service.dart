import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'dictionary_store.dart';

/// A problem with a backup file that the user should be told about in
/// plain words (wrong file, made by a newer app version, etc.).
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A finished backup, ready to hand to the "Save as" window.
class BackupFile {
  const BackupFile({required this.bytes, required this.suggestedName});
  final Uint8List bytes;
  final String suggestedName;
}

/// Creates and restores backups. See
/// `docs/decisions_log_backup_and_release.md`.
///
/// A backup is ONE `.zip` file containing:
/// ```
/// backup_info.json   what made it: app format, schema version, date, counts
/// database.sqlite    a complete copy of the database
/// photos/...         every character photo file (none yet; screens later)
/// ```
///
/// Restoring always **replaces** all current data. Before it does, an
/// automatic "safety copy" of the current data is saved into
/// [safetyDirectory] (the newest [safetyCopiesToKeep] are kept), so a
/// mistaken restore can be undone with [undoLastRestore].
///
/// All locations are constructor parameters so tests can point them at a
/// temp folder. The real app uses [BackupService.forApp].
class BackupService {
  BackupService({
    required this.store,
    required this.databaseFile,
    required this.photosDirectory,
    required this.safetyDirectory,
    required this.tempDirectory,
  });

  /// Wires up the real app's locations.
  static Future<BackupService> forApp(DictionaryStore store) async {
    return BackupService(
      store: store,
      databaseFile: await AppDatabase.databaseFile(),
      photosDirectory: await AppDatabase.photosDirectory(),
      safetyDirectory: await AppDatabase.safetyBackupsDirectory(),
      tempDirectory: await getTemporaryDirectory(),
    );
  }

  final DictionaryStore store;
  final File databaseFile;
  final Directory photosDirectory;
  final Directory safetyDirectory;
  final Directory tempDirectory;

  /// Identifies zips made by this app.
  static const String formatName = 'cantonese_dictionary_backup';

  /// Bump if the zip layout itself ever changes.
  static const int formatVersion = 1;

  static const int safetyCopiesToKeep = 5;

  static const String _infoName = 'backup_info.json';
  static const String _databaseName = 'database.sqlite';
  static const String _photosPrefix = 'photos/';

  String get _sep => Platform.pathSeparator;

  // ---- Back up ------------------------------------------------------------

  /// Builds a backup of everything currently stored.
  Future<BackupFile> createBackup() async {
    final now = DateTime.now();

    // 1. A clean copy of the database, via a temp file.
    await tempDirectory.create(recursive: true);
    final tempDb = File(
        '${tempDirectory.path}${_sep}backup_${now.microsecondsSinceEpoch}.sqlite');
    if (await tempDb.exists()) await tempDb.delete();
    await store.snapshotDatabaseTo(tempDb.path);
    final dbBytes = await tempDb.readAsBytes();
    await tempDb.delete();

    // 2. Photos that exist on disk.
    final archive = Archive();
    var photoCount = 0;
    for (final name in await store.photoFileNames()) {
      final file = File('${photosDirectory.path}$_sep$name');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile('$_photosPrefix$name', bytes.length, bytes));
      photoCount++;
    }

    // 3. Info file + database.
    final info = utf8.encode(const JsonEncoder.withIndent('  ').convert({
      'format': formatName,
      'formatVersion': formatVersion,
      'schemaVersion': AppDatabase.currentSchemaVersion,
      'createdAt': now.toIso8601String(),
      'characterCount': store.characters.length,
      'photoCount': photoCount,
    }));
    archive.addFile(ArchiveFile(_infoName, info.length, info));
    archive.addFile(ArchiveFile(_databaseName, dbBytes.length, dbBytes));

    final zipped = Uint8List.fromList(ZipEncoder().encode(archive));
    return BackupFile(bytes: zipped, suggestedName: backupFileName(now));
  }

  /// e.g. `cantonese_dictionary_backup_2026-09-19_1432.zip`
  static String backupFileName(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'cantonese_dictionary_backup_'
        '${t.year}-${two(t.month)}-${two(t.day)}_${two(t.hour)}${two(t.minute)}'
        '.zip';
  }

  // ---- Restore ------------------------------------------------------------

  /// Checks [zipBytes] is a usable backup WITHOUT changing anything.
  /// Returns the number of characters it contains. Throws
  /// [BackupException] with a user-readable message if not.
  int inspect(Uint8List zipBytes) => _parse(zipBytes).characterCount;

  /// Replaces ALL current data with the backup in [zipBytes]. Saves a
  /// safety copy of the current data first. Returns how many characters
  /// the restored backup contains.
  Future<int> restore(Uint8List zipBytes) async {
    final parsed = _parse(zipBytes);

    await _saveSafetyCopy();

    await store.replaceDatabase(() async {
      // Remove SQLite's side files so they can't be mixed with the new
      // database.
      for (final suffix in ['-wal', '-shm', '-journal']) {
        final side = File('${databaseFile.path}$suffix');
        if (await side.exists()) await side.delete();
      }
      // Write to a temp name first, then swap in, so an interrupted write
      // never leaves a half-written database.
      await databaseFile.parent.create(recursive: true);
      final incoming = File('${databaseFile.path}.restoring');
      await incoming.writeAsBytes(parsed.database, flush: true);
      await incoming.rename(databaseFile.path);

      if (await photosDirectory.exists()) {
        await photosDirectory.delete(recursive: true);
      }
      if (parsed.photos.isNotEmpty) {
        await photosDirectory.create(recursive: true);
        for (final entry in parsed.photos.entries) {
          await File('${photosDirectory.path}$_sep${entry.key}')
              .writeAsBytes(entry.value, flush: true);
        }
      }
    });
    return parsed.characterCount;
  }

  /// The newest automatic safety copy, or null if there is none.
  Future<File?> latestSafetyCopy() async {
    final copies = await _safetyCopies();
    return copies.isEmpty ? null : copies.last;
  }

  /// Restores the newest safety copy (undoing the last restore). This
  /// itself saves a new safety copy first, so it can be undone too.
  Future<int> undoLastRestore() async {
    final latest = await latestSafetyCopy();
    if (latest == null) {
      throw const BackupException('There is no restore to undo.');
    }
    final bytes = await latest.readAsBytes();
    // Delete it first so undo doesn't just re-pick the copy it's about to
    // create.
    await latest.delete();
    return restore(bytes);
  }

  Future<void> _saveSafetyCopy() async {
    final backup = await createBackup();
    await safetyDirectory.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await File('${safetyDirectory.path}${_sep}before_restore_$stamp.zip')
        .writeAsBytes(backup.bytes, flush: true);
    final copies = await _safetyCopies();
    for (var i = 0; i < copies.length - safetyCopiesToKeep; i++) {
      await copies[i].delete();
    }
  }

  /// Safety copies, oldest first.
  Future<List<File>> _safetyCopies() async {
    if (!await safetyDirectory.exists()) return [];
    final files = await safetyDirectory
        .list()
        .where((e) =>
            e is File &&
            e.path.split(_sep).last.startsWith('before_restore_') &&
            e.path.endsWith('.zip'))
        .cast<File>()
        .toList();
    int stampOf(File f) {
      final name = f.path.split(_sep).last;
      return int.tryParse(name.substring(
              'before_restore_'.length, name.length - '.zip'.length)) ??
          0;
    }

    files.sort((a, b) => stampOf(a).compareTo(stampOf(b)));
    return files;
  }

  _ParsedBackup _parse(Uint8List zipBytes) {
    const notABackup = BackupException(
        "This file isn't a backup made by this app.");

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw notABackup;
    }

    final infoFile = archive.findFile(_infoName);
    final dbFile = archive.findFile(_databaseName);
    if (infoFile == null || dbFile == null) throw notABackup;

    final Map<String, dynamic> info;
    try {
      info = jsonDecode(utf8.decode(_bytesOf(infoFile)))
          as Map<String, dynamic>;
    } catch (_) {
      throw notABackup;
    }
    if (info['format'] != formatName) throw notABackup;

    final backupFormat = (info['formatVersion'] as num?)?.toInt() ?? 0;
    final backupSchema = (info['schemaVersion'] as num?)?.toInt() ?? 0;
    if (backupFormat > formatVersion ||
        backupSchema > AppDatabase.currentSchemaVersion) {
      throw const BackupException(
          'This backup was made by a newer version of the app. '
          'Update the app first, then restore it.');
    }

    final database = _bytesOf(dbFile);
    const header = 'SQLite format 3';
    if (database.length < header.length ||
        String.fromCharCodes(database.sublist(0, header.length)) != header) {
      throw const BackupException('The backup file is damaged.');
    }

    final photos = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith(_photosPrefix)) continue;
      final name = file.name.substring(_photosPrefix.length);
      // Only plain file names: never let a zip write outside the folder.
      if (name.isEmpty || name.contains('/') || name.contains('\\') ||
          name.contains('..')) {
        continue;
      }
      photos[name] = _bytesOf(file);
    }

    return _ParsedBackup(
      database: database,
      photos: photos,
      characterCount: (info['characterCount'] as num?)?.toInt() ?? 0,
    );
  }

  static Uint8List _bytesOf(ArchiveFile file) {
    final data = file.readBytes();
    if (data == null) {
      throw const BackupException('The backup file is damaged.');
    }
    return Uint8List.fromList(data);
  }
}

class _ParsedBackup {
  const _ParsedBackup({
    required this.database,
    required this.photos,
    required this.characterCount,
  });
  final Uint8List database;
  final Map<String, Uint8List> photos;
  final int characterCount;
}
