import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../data/character_entry.dart';
import '../../widgets/tag_chip.dart';

/// Builds the "smart export" JSON file: typed characters, definitions,
/// tags, shortlist flags, flashcard stats, and resolved reference links.
/// Deliberately excludes `handwrittenSample` and internal `id`s — this is
/// meant to be a universally-readable record, not an app-internal backup.
Future<String> exportToJson(
  List<CharacterEntry> characters, {
  required Directory targetDirectory,
}) async {
  await targetDirectory.create(recursive: true);

  CharacterEntry? byId(int id) {
    for (final c in characters) {
      if (c.id == id) return c;
    }
    return null;
  }

  final records = characters.map((entry) {
    final stats = entry.flashcardStats;
    final totalAnswered = stats.timesCorrect + stats.timesIncorrect;
    return {
      'typedCharacter': entry.typedCharacter,
      'definition': entry.definition,
      'tags': TagChips.parseTags(entry.tags),
      'isStarred': entry.isStarred,
      'isHard': entry.isHard,
      'isArchived': entry.isArchived,
      'flashcardStats': {
        'timesSeen': stats.timesSeen,
        'timesCorrect': stats.timesCorrect,
        'timesIncorrect': stats.timesIncorrect,
        'accuracyPercent': totalAnswered == 0
            ? null
            : (stats.timesCorrect / totalAnswered * 100).round(),
      },
      'references': entry.referencedCharacterIds
          .map((id) => byId(id)?.typedCharacter)
          .whereType<String>()
          .toList(),
    };
  }).toList();

  final fileName =
      'cantonese_dictionary_export_${DateTime.now().millisecondsSinceEpoch}.json';
  final separator = Platform.pathSeparator;
  final dirPath = targetDirectory.path.endsWith(separator)
      ? targetDirectory.path
      : '${targetDirectory.path}$separator';
  final file = File('$dirPath$fileName');
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(records));
  return file.path;
}

/// Convenience wrapper for real app use: resolves the target directory via
/// `path_provider` instead of requiring the caller to pass one in. Tests
/// should call [exportToJson] directly against a temp directory instead.
Future<String> exportToAppDocuments(List<CharacterEntry> characters) async {
  final directory = await getApplicationDocumentsDirectory();
  return exportToJson(characters, targetDirectory: directory);
}
