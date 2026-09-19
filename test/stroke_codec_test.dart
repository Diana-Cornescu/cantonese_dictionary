import 'dart:typed_data';

import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/data/stroke_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null stays null both ways', () {
    expect(StrokeCodec.encode(null), isNull);
    expect(StrokeCodec.decode(null), isNull);
  });

  test('round-trips strokes, including an empty stroke', () {
    final strokes = [
      [
        const StrokePoint(x: 0.5, y: 1.25, t: 1726750000000),
        const StrokePoint(x: 100, y: 200, t: 1726750000016),
      ],
      <StrokePoint>[],
      [const StrokePoint(x: 7, y: 8, t: 1726750000500)],
    ];
    final bytes = StrokeCodec.encode(strokes)!;
    // 13 header + 4 per stroke (3) + 12 per point (3) = 61 bytes.
    expect(bytes.length, 61);

    final decoded = StrokeCodec.decode(bytes)!;
    expect(decoded.length, 3);
    expect(decoded[0][0].x, 0.5);
    expect(decoded[0][0].y, 1.25);
    expect(decoded[0][0].t, 1726750000000);
    expect(decoded[0][1].t, 1726750000016);
    expect(decoded[1], isEmpty);
    expect(decoded[2][0].x, 7);
    expect(decoded[2][0].t, 1726750000500);
  });

  test('an empty drawing (no strokes) round-trips', () {
    final decoded = StrokeCodec.decode(StrokeCodec.encode([]))!;
    expect(decoded, isEmpty);
  });

  test('rejects unknown versions and truncated data', () {
    final bytes = StrokeCodec.encode([
      [const StrokePoint(x: 1, y: 1, t: 0)],
    ])!;
    final wrongVersion = Uint8List.fromList(bytes)..[0] = 99;
    expect(() => StrokeCodec.decode(wrongVersion), throwsFormatException);
    final truncated = Uint8List.sublistView(bytes, 0, bytes.length - 3);
    expect(() => StrokeCodec.decode(truncated), throwsFormatException);
  });
}
