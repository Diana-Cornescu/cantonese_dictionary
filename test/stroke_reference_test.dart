import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cantonese_dictionary_app/data/stroke_reference.dart';
import 'package:cantonese_dictionary_app/widgets/reference_glyph_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny file in the same layout `tool/build_stroke_reference.py` writes:
/// one glyph, 丨 (U+4E28), one stroke: outline M 100 800, L 100 0, Z, and
/// a centre line from (100, 790) down to (100, 10).
ByteData _tinyFile({int version = 2}) {
  final glyph = BytesBuilder()
    ..addByte(1) // strokeCount
    ..add(_u16(3)) // commandCount
    ..addByte(0x4D) // M
    ..add(_i16(100))
    ..add(_i16(800))
    ..addByte(0x4C) // L
    ..add(_i16(100))
    ..add(_i16(0))
    ..addByte(0x5A) // Z
    ..add(_u16(2)) // medianPointCount
    ..add(_i16(100))
    ..add(_i16(790))
    ..add(_i16(100))
    ..add(_i16(10));
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
      final glyph = ref.glyphFor('丨')!;
      final strokes = glyph.strokes;
      expect(strokes, hasLength(1));
      expect(strokes[0].map((c) => c.op).toList(), ['M', 'L', 'Z']);
      expect(strokes[0][0].coords, [100, 800]);
      expect(strokes[0][1].coords, [100, 0]);
      expect(strokes[0][2].coords, isEmpty);
      expect(glyph.medians, [
        [(100.0, 790.0), (100.0, 10.0)],
      ]);
    });

    test('a missing glyph, or more than one character, is null', () {
      final ref = StrokeReference.fromBytes(_tinyFile());
      expect(ref.covers('一'), isFalse);
      expect(ref.glyphFor('一'), isNull);
      expect(ref.glyphFor('丨丨'), isNull);
      expect(ref.glyphFor(''), isNull);
    });

    test('rejects other files, other versions and truncated data', () {
      // Version 1 (no centre lines) isn't read any more.
      expect(() => StrokeReference.fromBytes(_tinyFile(version: 1)),
          throwsFormatException);
      final notOurs = ByteData.sublistView(
          Uint8List.fromList('PK\u0003\u0004nothing here'.codeUnits));
      expect(() => StrokeReference.fromBytes(notOurs), throwsFormatException);
      final whole = _tinyFile().buffer.asUint8List();
      final cut = ByteData.sublistView(whole, 0, whole.length - 3);
      final ref = StrokeReference.fromBytes(cut);
      expect(() => ref.glyphFor('丨'), throwsFormatException);
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
      final one = ref.glyphFor('一')!.strokes;
      expect(one, hasLength(1));
      expect(one[0], hasLength(17));
      expect(one[0].first.op, 'M');
      expect(one[0].first.coords, [518, 382]);
      expect(one[0].last.op, 'Z');
      final love = ref.glyphFor('愛')!;
      expect(love.strokes, hasLength(13));
      expect(love.medians, hasLength(13));
    });

    // The X-ray's arrows and numbers depend on the centre lines running
    // from where the pen goes down to where it lifts.
    test('centre lines give stroke order and direction', () {
      // 一 is written left to right.
      final one = ref.glyphFor('一')!.medians.single;
      expect(one.first.$1, lessThan(one.last.$1));

      // 人: first the left-falling stroke 丿, from the top down to the
      // left; then the right-falling ㇏, down to the right. (y grows
      // upwards in the data.)
      final person = ref.glyphFor('人')!.medians;
      expect(person, hasLength(2));
      final (pie, na) = (person[0], person[1]);
      expect(pie.first.$2, greaterThan(pie.last.$2)); // goes down
      expect(pie.first.$1, greaterThan(pie.last.$1)); // to the left
      expect(na.first.$2, greaterThan(na.last.$2)); // goes down
      expect(na.first.$1, lessThan(na.last.$1)); // to the right
      // 丿 starts higher up than ㇏.
      expect(pie.first.$2, greaterThan(na.first.$2));
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
      final stroke = ref.glyphFor('一')!.strokes[0];
      final bounds = glyphStrokePath(stroke, 100).getBounds();
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
