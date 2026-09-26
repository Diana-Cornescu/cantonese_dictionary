import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cantonese_dictionary_app/data/stroke_reference.dart';
import 'package:cantonese_dictionary_app/widgets/reference_glyph_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny file in the same layout `tool/build_stroke_reference.py` writes:
/// one glyph, 丨 (U+4E28), one stroke: M 100 800, L 100 0, Z.
ByteData _tinyFile({int version = 1}) {
  final glyph = BytesBuilder()
    ..addByte(1) // strokeCount
    ..add(_u16(3)) // commandCount
    ..addByte(0x4D) // M
    ..add(_i16(100))
    ..add(_i16(800))
    ..addByte(0x4C) // L
    ..add(_i16(100))
    ..add(_i16(0))
    ..addByte(0x5A); // Z
  const headerSize = 4 + 1 + 4 + 8;
  final file = BytesBuilder()
    ..add('SREF'.codeUnits)
    ..addByte(version)
    ..add(_u32(1))
    ..add(_u32(0x4E28))
    ..add(_u32(headerSize))
    ..add(glyph.toBytes());
  return ByteData.sublistView(file.toBytes());
}

List<int> _u16(int v) =>
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List();
List<int> _i16(int v) =>
    (ByteData(2)..setInt16(0, v, Endian.little)).buffer.asUint8List();
List<int> _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

void main() {
  group('reading the file format', () {
    test('finds a glyph and decodes its commands', () {
      final ref = StrokeReference.fromBytes(_tinyFile());
      expect(ref.length, 1);
      expect(ref.covers('丨'), isTrue);
      final strokes = ref.strokesFor('丨')!;
      expect(strokes, hasLength(1));
      expect(strokes[0].map((c) => c.op).toList(), ['M', 'L', 'Z']);
      expect(strokes[0][0].coords, [100, 800]);
      expect(strokes[0][1].coords, [100, 0]);
      expect(strokes[0][2].coords, isEmpty);
    });

    test('a missing glyph, or more than one character, is null', () {
      final ref = StrokeReference.fromBytes(_tinyFile());
      expect(ref.covers('一'), isFalse);
      expect(ref.strokesFor('一'), isNull);
      expect(ref.strokesFor('丨丨'), isNull);
      expect(ref.strokesFor(''), isNull);
    });

    test('rejects other files, other versions and truncated data', () {
      expect(() => StrokeReference.fromBytes(_tinyFile(version: 2)),
          throwsFormatException);
      final notOurs = ByteData.sublistView(
          Uint8List.fromList('PK\u0003\u0004nothing here'.codeUnits));
      expect(() => StrokeReference.fromBytes(notOurs), throwsFormatException);
      final whole = _tinyFile().buffer.asUint8List();
      final cut = ByteData.sublistView(whole, 0, whole.length - 3);
      final ref = StrokeReference.fromBytes(cut);
      expect(() => ref.strokesFor('丨'), throwsFormatException);
    });
  });

  // The bundled file itself, read from disk (flutter test runs from the
  // project folder). Checks the Python build script and this reader agree.
  group('the bundled stroke data', () {
    late StrokeReference ref;
    setUpAll(() {
      final bytes = File(StrokeReference.assetPath).readAsBytesSync();
      ref = StrokeReference.fromBytes(ByteData.sublistView(bytes));
    });

    test('covers the expected characters', () {
      expect(ref.length, 9574);
      for (final glyph in ['一', '愛', '时', '间', '森', '林', '人']) {
        expect(ref.covers(glyph), isTrue, reason: glyph);
      }
      // A Cantonese-only character the data doesn't have.
      expect(ref.covers('咗'), isFalse);
    });

    test('decodes real glyphs', () {
      final one = ref.strokesFor('一')!;
      expect(one, hasLength(1));
      expect(one[0], hasLength(17));
      expect(one[0].first.op, 'M');
      expect(one[0].first.coords, [518, 382]);
      expect(one[0].last.op, 'Z');
      expect(ref.strokesFor('愛'), hasLength(13));
    });
  });

  group('placing the reference in a box', () {
    test('maps the grid corners to the box corners', () {
      expect(StrokeReference.toBox(0, 900, 1024), (0.0, 0.0));
      expect(StrokeReference.toBox(1024, -124, 512), (512.0, 512.0));
      expect(StrokeReference.toBox(512, 388, 100), (50.0, 50.0));
    });

    test('a stroke path lands inside its box', () {
      final bytes = File(StrokeReference.assetPath).readAsBytesSync();
      final ref = StrokeReference.fromBytes(ByteData.sublistView(bytes));
      final bounds = glyphStrokePath(ref.strokesFor('一')![0], 100).getBounds();
      expect(const Rect.fromLTWH(0, 0, 100, 100).contains(bounds.topLeft),
          isTrue);
      expect(const Rect.fromLTWH(0, 0, 100, 100).contains(bounds.bottomRight),
          isTrue);
      // 一 is a wide, flat stroke across the middle.
      expect(bounds.width, greaterThan(60));
      expect(bounds.height, lessThan(20));
    });
  });

  test('glyphsOf splits an entry into characters to write', () {
    expect(StrokeReference.glyphsOf('时间'), ['时', '间']);
    expect(StrokeReference.glyphsOf('愛'), ['愛']);
    expect(StrokeReference.glyphsOf(' 森 林 '), ['森', '林']);
    expect(StrokeReference.glyphsOf(''), isEmpty);
    expect(StrokeReference.glyphsOf('  '), isEmpty);
  });
}
