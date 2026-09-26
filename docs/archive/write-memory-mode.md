# Archived: Memory mode on the Write tab

**Built 2026-09-26, removed the same night, never released.** Practice
mode with the 👁 Hide / Show X-ray button covers what Memory mode did (hide
the X-ray, write from memory, show it to check), so the choice between two
modes was dropped. Kept here in case it's wanted back; the decision is in
`decisions/writing-practice.md`.

## What it did

- A **Mode** choice at the top of the Write tab's … panel: **Memory mode**
  (the default) or **Practice mode**, one always selected, **saved** in
  the settings table under `write_mode`.
- **Memory mode:** the box started with only the 米字格 guide. You wrote the
  character, tapped **Check**, and the box froze (read-only) with the
  X-ray drawn under your ink and the character shown as text below it.
  **Try again** cleared the box; **Next** moved on.
- **Practice mode:** as today.

## Leftover data

Anyone who opened the … panel before the removal may have a `write_mode`
row in `app_settings`. Nothing reads it now; it's harmless, and restoring
this code would pick it up again.

## Restoring it

Put these pieces back into `lib/features/write/write_practice_screen.dart`
(state class unless noted), and the test back as `test/write_mode_test.dart`.

**The enum** (top level, above the screen class):

```dart
/// How the Write tab asks, chosen in its options panel (2026-09-26). One
/// is always selected, and the choice is **remembered** (and rides along
/// in backups), like Flashcards' Text only / Text + drawing.
///
/// The order here is the order in the panel. The stored string is the
/// constant's `name`, so **renaming one silently resets the setting**;
/// `test/write_mode_test.dart` pins them.
enum WriteMode {
  /// Write from memory, then **Check** shows the X-ray under your ink;
  /// **Try again** or **Next**.
  memory('Memory mode', 'Write from memory, then check the stroke order'),

  /// The X-ray is there from the start, to write over; just **Next**.
  practice('Practice mode', 'Write over the stroke order and direction');

  const WriteMode(this.label, this.description);
  final String label;
  final String description;

  static const settingKey = 'write_mode';

  /// The mode stored under [settingKey]; anything unrecognised (never set,
  /// or written by a newer version) is [memory].
  static WriteMode byId(String? id) {
    for (final mode in values) {
      if (mode.name == id) return mode;
    }
    return memory;
  }
}
```

**State fields:**

```dart
  late WriteMode _mode =
      WriteMode.byId(widget.store.setting(WriteMode.settingKey));

  bool _checked = false;
```

(`_resetBox()` also set `_checked = false;`.)

**Options panel**, before the "Which cards" heading:

```dart
                  heading('Mode'),
                  for (final mode in WriteMode.values)
                    ListTile(
                      leading: Icon(mode == _mode
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                      title: Text(mode.label),
                      subtitle: Text(mode.description),
                      selected: mode == _mode,
                      onTap: () {
                        _setMode(mode);
                        setSheetState(() {});
                      },
                    ),
                  const Divider(height: 24),
```

**Methods:**

```dart
  /// Saved straight away. Starts the current character's box again, but
  /// keeps the card.
  Future<void> _setMode(WriteMode value) async {
    if (value == _mode) return;
    setState(() {
      _mode = value;
      _resetBox();
    });
    await widget.store.setSetting(WriteMode.settingKey, value.name);
  }

  void _check() => setState(() => _checked = true);

  void _tryAgain() => setState(_resetBox);
```

**In `_buildCard`**, how the mode decided what the box showed:

```dart
    final practice = _mode == WriteMode.practice;
    // Memory mode shows the X-ray once checked; Practice mode throughout,
    // unless it's been hidden with the 👁 button.
    final showXray = practice ? !_xrayHidden : _checked;
    // Only a checked Memory-mode box stops taking ink.
    final frozen = !practice && _checked;
```

The canvas took its key and read-only state from that:

```dart
            key: ValueKey('$_index/$_glyph/$_attempt/$frozen/${_mode.name}'),
            readOnly: frozen,
            initialStrokes: frozen ? _strokes : null,
```

The answer as text under the box, once checked:

```dart
        // Memory mode: the answer as text, once checked. Blank space
        // otherwise, so the buttons stay put.
        SizedBox(
          height: 48,
          child: Center(
            child: frozen
                ? Text(glyph, style: const TextStyle(fontSize: 36))
                : null,
          ),
        ),
        const SizedBox(height: 8),
```

And the buttons: Practice mode's row came first (`if (practice) ...`), then:

```dart
        else if (_checked)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _tryAgain,
                child: const Text('Try again'),
              ),
              next,
            ],
          )
        else
          FilledButton(onPressed: _check, child: const Text('Check')),
```

**The test** (`test/write_mode_test.dart`):

```dart
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
```
