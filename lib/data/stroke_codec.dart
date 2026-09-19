import 'dart:typed_data';

import 'character_entry.dart';

/// Packs a handwriting sample into a compact binary blob for the database,
/// and unpacks it again. Pure Dart, no Flutter or Drift imports, so it can
/// be unit-tested on its own.
///
/// Why binary instead of JSON text: one point as JSON (`{"x":12.5,...}`)
/// is ~35 bytes; packed here it's 12 bytes, so roughly 3x smaller. See
/// `docs/decisions_log_sqlite_drift.md` (decision 3) for the size math.
///
/// Layout (little-endian), format version 1:
/// ```
/// [uint8  version = 1]
/// [int64  baseT]            // first point's timestamp (ms since epoch)
/// [uint32 strokeCount]
///   per stroke:
///   [uint32 pointCount]
///     per point:
///     [float32 x] [float32 y] [uint32 dt]   // dt = t - baseT, in ms
/// ```
/// Timestamps are stored as an offset from the first point so each one fits
/// in 4 bytes instead of 8. Coordinates are float32, which is far more
/// precision than a finger or mouse on a canvas can produce.
///
/// If the layout ever needs to change, bump [formatVersion] and keep
/// [decode] able to read version 1, so already-saved drawings still load.
class StrokeCodec {
  StrokeCodec._();

  static const int formatVersion = 1;

  /// Returns `null` for `null` (no drawing recorded).
  static Uint8List? encode(List<List<StrokePoint>>? strokes) {
    if (strokes == null) return null;

    var pointTotal = 0;
    for (final stroke in strokes) {
      pointTotal += stroke.length;
    }
    // 1 (version) + 8 (baseT) + 4 (strokeCount)
    // + 4 per stroke (pointCount) + 12 per point.
    final byteLength = 13 + 4 * strokes.length + 12 * pointTotal;
    final data = ByteData(byteLength);

    var baseT = 0;
    for (final stroke in strokes) {
      if (stroke.isNotEmpty) {
        baseT = stroke.first.t;
        break;
      }
    }

    var offset = 0;
    data.setUint8(offset, formatVersion);
    offset += 1;
    data.setInt64(offset, baseT, Endian.little);
    offset += 8;
    data.setUint32(offset, strokes.length, Endian.little);
    offset += 4;
    for (final stroke in strokes) {
      data.setUint32(offset, stroke.length, Endian.little);
      offset += 4;
      for (final point in stroke) {
        data.setFloat32(offset, point.x, Endian.little);
        offset += 4;
        data.setFloat32(offset, point.y, Endian.little);
        offset += 4;
        // Clamp to the uint32 range: a negative offset would only happen if
        // the device clock jumped backwards mid-drawing.
        final dt = point.t - baseT;
        data.setUint32(
            offset, dt < 0 ? 0 : (dt > 0xFFFFFFFF ? 0xFFFFFFFF : dt),
            Endian.little);
        offset += 4;
      }
    }
    return data.buffer.asUint8List();
  }

  /// Returns `null` for `null` (no drawing recorded). Throws a
  /// [FormatException] if the blob has an unknown version or is truncated.
  static List<List<StrokePoint>>? decode(Uint8List? bytes) {
    if (bytes == null) return null;
    if (bytes.isEmpty) {
      throw const FormatException('Empty handwriting blob');
    }
    final data = ByteData.sublistView(bytes);
    try {
      var offset = 0;
      final version = data.getUint8(offset);
      offset += 1;
      if (version != formatVersion) {
        throw FormatException('Unknown handwriting format version $version');
      }
      final baseT = data.getInt64(offset, Endian.little);
      offset += 8;
      final strokeCount = data.getUint32(offset, Endian.little);
      offset += 4;

      final strokes = <List<StrokePoint>>[];
      for (var s = 0; s < strokeCount; s++) {
        final pointCount = data.getUint32(offset, Endian.little);
        offset += 4;
        final points = <StrokePoint>[];
        for (var p = 0; p < pointCount; p++) {
          final x = data.getFloat32(offset, Endian.little);
          offset += 4;
          final y = data.getFloat32(offset, Endian.little);
          offset += 4;
          final dt = data.getUint32(offset, Endian.little);
          offset += 4;
          points.add(StrokePoint(x: x, y: y, t: baseT + dt));
        }
        strokes.add(points);
      }
      return strokes;
    } on RangeError {
      throw const FormatException('Truncated handwriting blob');
    }
  }
}
