import 'package:cantonese_dictionary_app/features/write/write_practice_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Write tab's Memory / Practice choice is saved in the settings table
/// as the enum constant's `name` (2026-09-26). Renaming a constant would
/// silently reset everyone's choice, so the strings are pinned here, the
/// same way `flashcard_face_test.dart` pins the flashcard setting.
void main() {
  test('the stored names are stable', () {
    expect(WriteMode.memory.name, 'memory');
    expect(WriteMode.practice.name, 'practice');
    expect(WriteMode.settingKey, 'write_mode');
  });

  test('byId round-trips every value', () {
    for (final mode in WriteMode.values) {
      expect(WriteMode.byId(mode.name), mode);
    }
  });

  test('never set, or unrecognised, falls back to Memory mode', () {
    expect(WriteMode.byId(null), WriteMode.memory);
    expect(WriteMode.byId(''), WriteMode.memory);
    expect(WriteMode.byId('somethingElse'), WriteMode.memory);
  });

  test('Memory mode is listed first in the options panel', () {
    expect(WriteMode.values.first, WriteMode.memory);
  });
}
