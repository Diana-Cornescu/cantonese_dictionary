import 'dart:convert';
import 'dart:io';

import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/features/export/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

CharacterEntry _entry({
  required int id,
  required String typedCharacter,
  String definition = 'a definition',
  String tags = 'food, verb',
  int timesCorrect = 0,
  int timesIncorrect = 0,
  List<int> referencedCharacterIds = const [],
}) {
  final now = DateTime.now();
  return CharacterEntry(
    id: id,
    typedCharacter: typedCharacter,
    // A real (non-empty) stroke sample, so the test can prove export
    // actually excludes it rather than it being trivially absent.
    handwrittenSample: [
      [StrokePoint(x: 0, y: 0, t: 0), StrokePoint(x: 1, y: 1, t: 5)],
    ],
    definition: definition,
    notes: '',
    tags: tags,
    isStarred: true,
    isHard: false,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
    flashcardStats: FlashcardStats(
      timesSeen: timesCorrect + timesIncorrect,
      timesCorrect: timesCorrect,
      timesIncorrect: timesIncorrect,
    ),
    referencedCharacterIds: referencedCharacterIds,
  );
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('export_service_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
      'exports the expected shape, resolves references, excludes '
      'handwriting/id', () async {
    final a = _entry(id: 1, typedCharacter: 'A', referencedCharacterIds: [2]);
    final b = _entry(
      id: 2,
      typedCharacter: 'B',
      timesCorrect: 3,
      timesIncorrect: 1,
    );
    final c = _entry(id: 3, typedCharacter: 'C'); // timesSeen == 0

    final path = await exportToJson([a, b, c], targetDirectory: tempDir);
    final contents = await File(path).readAsString();
    final decoded = jsonDecode(contents) as List<dynamic>;

    expect(decoded.length, 3);

    final recordA = decoded[0] as Map<String, dynamic>;
    expect(recordA['typedCharacter'], 'A');
    expect(recordA['tags'], ['food', 'verb']);
    expect(recordA['isStarred'], true);
    expect(recordA['references'], ['B']);
    expect(recordA.containsKey('handwrittenSample'), isFalse);
    expect(recordA.containsKey('id'), isFalse);
    expect((recordA['flashcardStats'] as Map)['accuracyPercent'], isNull);

    final recordB = decoded[1] as Map<String, dynamic>;
    expect((recordB['flashcardStats'] as Map)['accuracyPercent'], 75);

    final recordC = decoded[2] as Map<String, dynamic>;
    expect((recordC['flashcardStats'] as Map)['timesSeen'], 0);
    expect((recordC['flashcardStats'] as Map)['accuracyPercent'], isNull);
  });
}
