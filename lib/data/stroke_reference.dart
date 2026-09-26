import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// One drawing command of a reference stroke's outline, in Make Me a
/// Hanzi's coordinates (see [StrokeReference]).
///
/// [op] is one of `M` (move to), `L` (line to), `Q` (quadratic curve: one
/// control point, then the end point), `C` (cubic curve: two control
/// points, then the end point) or `Z` (close). [coords] holds the points as
/// x, y pairs, flattened: 2 numbers for M and L, 4 for Q, 6 for C, none
/// for Z.
class GlyphCommand {
  const GlyphCommand(this.op, this.coords);

  final String op;
  final List<double> coords;
}

/// The outline of one stroke: a closed shape, not a centre line.
typedef GlyphStroke = List<GlyphCommand>;

/// A character's reference form: for each stroke, in stroke order, its
/// outline and its centre line ("median").
class ReferenceGlyph {
  const ReferenceGlyph({required this.strokes, required this.medians});

  /// Each stroke's outline, in stroke order.
  final List<GlyphStroke> strokes;

  /// Each stroke's centre line, same order as [strokes], as (x, y) points
  /// running from where the pen goes down to where it lifts. So the first
  /// point is where the stroke starts, and the list's order is its
  /// direction. Drives the X-ray (numbers and arrows) on the Write tab.
  final List<List<(double, double)>> medians;
}

/// The correct written form of each character, for the Write tab.
///
/// Read from `assets/stroke_reference.bin`, which is built from Make Me a
/// Hanzi's `graphics.txt` by `tool/build_stroke_reference.py` (that file
/// documents the byte layout). About 9,500 common simplified and
/// traditional characters; many Cantonese-only ones (咗, 冇, 佢…) aren't in
/// it. See `docs/decisions/writing-practice.md`.
///
/// **Coordinates** are the dataset's own: a 1024 × 1024 grid whose top edge
/// is y = 900 and bottom edge y = −124, with y growing *upwards*. Use
/// [toBox] to place a point in an on-screen box.
///
/// The whole file (~15 MB) is held in memory once loaded; each glyph is
/// only decoded when asked for. Nothing is ever written back.
class StrokeReference {
  StrokeReference._(this._data, this._index);

  /// Where the file is bundled. Listed under `assets:` in `pubspec.yaml`.
  static const assetPath = 'assets/stroke_reference.bin';

  /// 2 since 2026-09-26, when the centre lines were added. Version 1 files
  /// aren't read: the file ships with the app, so it's always current.
  static const int formatVersion = 2;

  /// Size of the dataset's square grid.
  static const double gridSize = 1024;

  /// The y value of the grid's top edge.
  static const double gridTop = 900;

  final ByteData _data;

  /// Code point → byte offset of that glyph's data.
  final Map<int, int> _index;

  static Future<StrokeReference>? _loading;

  /// Loads the bundled file the first time it's needed (the Write tab
  /// opening) and hands back the same instance after that.
  static Future<StrokeReference> load() => _loading ??= _loadOnce();

  static Future<StrokeReference> _loadOnce() async {
    try {
      final data = await rootBundle.load(assetPath);
      return StrokeReference.fromBytes(data);
    } catch (_) {
      // Let a later attempt try again rather than caching the failure.
      _loading = null;
      rethrow;
    }
  }

  /// Reads the index from [data]. Throws a [FormatException] if it isn't a
  /// stroke reference file this version understands.
  factory StrokeReference.fromBytes(ByteData data) {
    try {
      if (data.getUint8(0) != 0x53 || // S
          data.getUint8(1) != 0x52 || // R
          data.getUint8(2) != 0x45 || // E
          data.getUint8(3) != 0x46) {
        // F
        throw const FormatException('Not a stroke reference file');
      }
      final version = data.getUint8(4);
      if (version != formatVersion) {
        throw FormatException('Unknown stroke reference version $version');
      }
      final count = data.getUint32(5, Endian.little);
      final index = <int, int>{};
      for (var i = 0; i < count; i++) {
        final at = 9 + 8 * i;
        index[data.getUint32(at, Endian.little)] =
            data.getUint32(at + 4, Endian.little);
      }
      return StrokeReference._(data, index);
    } on RangeError {
      throw const FormatException('Truncated stroke reference file');
    }
  }

  /// How many characters the file covers.
  int get length => _index.length;

  /// Whether [glyph] (a single character) is covered.
  bool covers(String glyph) {
    final runes = glyph.runes;
    return runes.length == 1 && _index.containsKey(runes.first);
  }

  /// [glyph]'s reference form, or `null` if it isn't covered.
  ReferenceGlyph? glyphFor(String glyph) {
    final runes = glyph.runes;
    if (runes.length != 1) return null;
    final start = _index[runes.first];
    if (start == null) return null;
    try {
      var at = start;
      final strokeCount = _data.getUint8(at);
      at += 1;
      final strokes = <GlyphStroke>[];
      final medians = <List<(double, double)>>[];
      for (var s = 0; s < strokeCount; s++) {
        final commandCount = _data.getUint16(at, Endian.little);
        at += 2;
        final commands = <GlyphCommand>[];
        for (var c = 0; c < commandCount; c++) {
          final op = String.fromCharCode(_data.getUint8(at));
          at += 1;
          final numbers = 2 * _pointsPerOp(op);
          final coords = <double>[];
          for (var n = 0; n < numbers; n++) {
            coords.add(_data.getInt16(at, Endian.little).toDouble());
            at += 2;
          }
          commands.add(GlyphCommand(op, coords));
        }
        strokes.add(commands);
        final pointCount = _data.getUint16(at, Endian.little);
        at += 2;
        final median = <(double, double)>[];
        for (var p = 0; p < pointCount; p++) {
          median.add((
            _data.getInt16(at, Endian.little).toDouble(),
            _data.getInt16(at + 2, Endian.little).toDouble(),
          ));
          at += 4;
        }
        medians.add(median);
      }
      return ReferenceGlyph(strokes: strokes, medians: medians);
    } on RangeError {
      throw const FormatException('Truncated stroke reference file');
    }
  }

  static int _pointsPerOp(String op) => switch (op) {
        'M' || 'L' => 1,
        'Q' => 2,
        'C' => 3,
        'Z' => 0,
        _ => throw FormatException('Unknown path command $op'),
      };

  /// Where the dataset point ([x], [y]) lands in a square box [size]
  /// pixels wide, with (0, 0) at the box's top-left corner.
  static (double, double) toBox(double x, double y, double size) =>
      (x * size / gridSize, (gridTop - y) * size / gridSize);

  /// The characters to write for [typed], one per box: its code points,
  /// minus spaces. `时间` → `[时, 间]`.
  static List<String> glyphsOf(String typed) => [
        for (final rune in typed.runes)
          if (String.fromCharCode(rune).trim().isNotEmpty)
            String.fromCharCode(rune),
      ];
}
