import 'package:cantonese_dictionary_app/features/flashcards/flashcard_mode_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The flashcard "what does the character side show" choice is stored in
/// the settings table as a plain string — the enum constant's `name`. That
/// makes renaming a constant a silent data change: everyone's saved
/// preference would stop matching and quietly fall back to the default.
///
/// These two strings are therefore pinned. If a rename is genuinely wanted,
/// this test has to be updated deliberately, and the old value migrated.
void main() {
  test('the stored names are stable', () {
    expect(CharacterFace.typedAndDrawing.name, 'typedAndDrawing');
    expect(CharacterFace.typedOnly.name, 'typedOnly');
    expect(CharacterFace.settingKey, 'flashcard_character_face');
  });

  test('byId round-trips every value', () {
    for (final face in CharacterFace.values) {
      expect(CharacterFace.byId(face.name), face);
    }
  });

  test('never set, or unrecognised, falls back to Text only', () {
    // Text only has been the default since 2026-09-25 (was Text + drawing).
    expect(CharacterFace.byId(null), CharacterFace.typedOnly);
    expect(CharacterFace.byId(''), CharacterFace.typedOnly);
    // e.g. written by a newer version of the app, then opened by this one.
    expect(CharacterFace.byId('somethingElse'), CharacterFace.typedOnly);
  });

  test('Text only is listed first in the options panel', () {
    expect(CharacterFace.values.first, CharacterFace.typedOnly);
  });
}
