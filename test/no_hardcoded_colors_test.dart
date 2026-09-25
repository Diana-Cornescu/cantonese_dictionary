import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the 2026-09-25 color restructure from drifting back.
///
/// Every color value lives in `lib/theme/` (`AppRawColors` and the color
/// themes in `app_palettes.dart`). Everywhere else asks for a color by what
/// it's for: the theme, `AppColors` (the colors that mean something) or
/// `context.appColors` (the light/dark roles). See the note at the top of
/// `lib/theme/app_colors.dart`.
///
/// This test reads the source files, so it runs from the project folder
/// (which `flutter test` does).
void main() {
  test('no file outside lib/theme/ writes a color value', () {
    final forbidden = <String, RegExp>{
      // Flutter's built-in named colors: Colors.white, Colors.grey, …
      // (but not AppColors.x, which is the allowed way in).
      'Colors.<name>': RegExp(r'(?<![A-Za-z])Colors\.[a-zA-Z]'),
      'Color(0x…)': RegExp(r'\bColor\(\s*0x'),
      'Color.fromARGB / fromRGBO': RegExp(r'\bColor\.from(ARGB|RGBO)\('),
      // The raw list is for the theme files only.
      'AppRawColors': RegExp(r'\bAppRawColors\b'),
    };

    final problems = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !_isThemeFile(f.path));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = _withoutComment(lines[i]);
        forbidden.forEach((what, pattern) {
          if (pattern.hasMatch(code)) {
            problems.add('${file.path}:${i + 1}  $what  →  ${lines[i].trim()}');
          }
        });
      }
    }

    expect(problems, isEmpty,
        reason: 'Use the theme, AppColors or context.appColors instead '
            '(see lib/theme/app_colors.dart):\n${problems.join('\n')}');
  });
}

bool _isThemeFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.startsWith('lib/theme/');
}

/// The line with any `//` comment cut off, so a comment that *mentions*
/// `Colors.white` isn't counted. Good enough for this codebase: no string
/// literal here contains `//` followed by a color.
String _withoutComment(String line) {
  final index = line.indexOf('//');
  return index == -1 ? line : line.substring(0, index);
}
