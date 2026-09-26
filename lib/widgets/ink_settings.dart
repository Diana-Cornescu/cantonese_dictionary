import 'package:flutter/widgets.dart';

/// How handwriting ink is drawn everywhere in the app: pen size and
/// smoothing, chosen in Settings → Handwriting (2026-09-26).
///
/// Both are **display settings only**. What's stored for a drawing is the
/// raw points, whatever these are set to, so changing them later redraws
/// every drawing, old ones included, and nothing is lost by turning
/// smoothing off again.
///
/// Saved in the settings table like the color theme (so they're included
/// in backups), and handed down the widget tree by [InkSettingsScope],
/// which `main.dart` puts above every screen. [HandwritingCanvas] reads
/// them with [InkSettings.of].
@immutable
class InkSettings {
  const InkSettings({this.width = defaultWidth, this.smooth = true});

  /// Settings-table keys. **Don't rename**: a new key silently resets
  /// everyone's choice (`test/ink_settings_test.dart` pins them).
  static const widthKey = 'ink_width';
  static const smoothKey = 'ink_smoothing';

  /// Pen size in logical pixels. 4 is what the app always drew with.
  static const double defaultWidth = 4;

  /// The Settings slider's range. Capped at 10 so strokes don't merge
  /// into a blob in the smaller boxes (the flashcard preview, a dense
  /// character).
  static const double minWidth = 2;
  static const double maxWidth = 10;

  final double width;

  /// Draw each stroke as a smooth curve through its points instead of
  /// straight segments between them. **On by default** (2026-09-26); only
  /// a stored `false` turns it off.
  final bool smooth;

  /// From the two stored strings. Missing or unreadable values fall back
  /// to the defaults; a width outside the range is clamped into it.
  factory InkSettings.fromStored(String? width, String? smooth) {
    final parsed = double.tryParse(width ?? '');
    return InkSettings(
      width: parsed == null || parsed.isNaN
          ? defaultWidth
          : parsed.clamp(minWidth, maxWidth).toDouble(),
      smooth: smooth != 'false',
    );
  }

  /// The settings in force at [context], or the defaults if there's no
  /// [InkSettingsScope] above it (e.g. a test that builds a bare widget).
  static InkSettings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<InkSettingsScope>()
          ?.settings ??
      const InkSettings();

  @override
  bool operator ==(Object other) =>
      other is InkSettings && other.width == width && other.smooth == smooth;

  @override
  int get hashCode => Object.hash(width, smooth);
}

/// Makes [settings] available to everything below it via
/// [InkSettings.of]. Placed in `MaterialApp.builder`, so dialogs and every
/// tab see it too.
class InkSettingsScope extends InheritedWidget {
  const InkSettingsScope({
    super.key,
    required this.settings,
    required super.child,
  });

  final InkSettings settings;

  @override
  bool updateShouldNotify(InkSettingsScope oldWidget) =>
      oldWidget.settings != settings;
}
