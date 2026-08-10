import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Low-level, atomic JSON file storage. This class knows nothing about
/// characters/dictionaries — it just reads and writes one JSON file safely.
///
/// There are no separate image files anywhere in this app. A "handwritten
/// sample" is never rasterized to a bitmap; it's stored as a list of
/// strokes, each a list of `{x, y, t}` points (see `StrokePoint` in
/// `character_entry.dart`), and the drawing is simply replayed from those
/// coordinates whenever it's shown. Those points live inline in this same
/// JSON file, one `handwrittenSample` array per character entry, right next
/// to that character's typed text/definition/notes/tags/stats — there is
/// only ever this one file.
///
/// The target [file] is an injected constructor parameter on purpose, so
/// tests can point this at a temp file and never touch real app data or
/// `path_provider`. Use [StorageService.createDefault] to get an instance
/// wired to the real platform application-documents directory.
class StorageService {
  StorageService(this.file);

  /// The JSON file this instance reads from and writes to.
  final File file;

  /// The file name used inside the app's documents directory in real app
  /// use (see [createDefault]). Not used when a [file] is injected directly.
  ///
  /// Renamed from `cantonese_dictionary_data.json` — the old name read as
  /// if it might hold image data specifically; it's always been the whole
  /// dictionary (see the class doc above).
  static const String defaultFileName = 'cantonese_dictionary_entries.json';

  /// The file name used before the rename above. Kept only so
  /// [createDefault] can migrate an existing install's data forward the
  /// first time it runs after updating.
  static const String _legacyFileName = 'cantonese_dictionary_data.json';

  /// Builds a [StorageService] pointed at the real app's documents
  /// directory via `path_provider`. This is the only place in the app that
  /// calls `path_provider` — tests should use the plain constructor with a
  /// temp-directory [File] instead.
  static Future<StorageService> createDefault() async {
    final directory = await getApplicationDocumentsDirectory();
    final separator = Platform.pathSeparator;
    final dirPath = directory.path.endsWith(separator)
        ? directory.path
        : '${directory.path}$separator';
    final target = File('$dirPath$defaultFileName');
    // One-time migration: if this looks like an existing install (no file
    // under the new name yet, but one under the old name), copy the old
    // file's contents over so the rename doesn't look like data loss.
    if (!await target.exists()) {
      final legacy = File('$dirPath$_legacyFileName');
      if (await legacy.exists()) {
        await legacy.copy(target.path);
      }
    }
    return StorageService(target);
  }

  /// Reads and JSON-decodes [file]. Returns `null` if the file doesn't
  /// exist yet or is empty, so callers can tell "no data yet" apart from
  /// "an empty object" and decide how to seed initial data.
  Future<Map<String, dynamic>?> readJson() async {
    if (!await file.exists()) return null;
    final contents = await file.readAsString();
    if (contents.trim().isEmpty) return null;
    return jsonDecode(contents) as Map<String, dynamic>;
  }

  /// JSON-encodes [data] and writes it atomically: the encoded bytes go to
  /// a sibling `<file>.tmp` file first, which is then renamed over [file].
  /// A crash or interruption mid-write therefore either leaves the old
  /// [file] completely intact, or leaves a stray `.tmp` file — it can never
  /// leave [file] itself half-written.
  Future<void> writeJson(Map<String, dynamic> data) async {
    await file.parent.create(recursive: true);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(data), flush: true);
    await tempFile.rename(file.path);
  }
}
