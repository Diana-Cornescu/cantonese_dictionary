import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/stroke_reference.dart';

/// Paints the background of a Write-tab box: a faint 米字格 guide (a cross
/// and both diagonals, to help with proportions) and, when [reference] is
/// set, the character's **X-ray** underneath your ink:
///  - each stroke's outline, filled in pale grey,
///  - its centre line, with an **arrowhead** where the pen lifts, so you
///    can see the direction,
///  - a numbered **badge** where the pen goes down: ①, ②, ③… in stroke
///    order.
///
/// Memory mode shows the X-ray after Check; Practice mode shows it from
/// the start, to write over (2026-09-26).
///
/// Used as `HandwritingCanvas.backgroundPainter`, so it sits on the paper
/// and under the strokes. Expects a square box; the reference is scaled to
/// the box's width.
class WritingGuidePainter extends CustomPainter {
  WritingGuidePainter({
    required this.guideColor,
    required this.outlineColor,
    required this.strokeOrderColor,
    required this.onStrokeOrderColor,
    this.reference,
  });

  final Color guideColor;

  /// The character's reference form, or null to show only the guide.
  final ReferenceGlyph? reference;

  /// Fill for the stroke outlines.
  final Color outlineColor;

  /// The centre lines, arrowheads and number badges…
  final Color strokeOrderColor;

  /// …and the numbers inside the badges.
  final Color onStrokeOrderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    _paintGuide(canvas, size);

    final glyph = reference;
    if (glyph == null) return;

    final fill = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;
    for (final stroke in glyph.strokes) {
      canvas.drawPath(glyphStrokePath(stroke, side), fill);
    }

    final line = Paint()
      ..color = strokeOrderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, side * 0.012)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final solid = Paint()
      ..color = strokeOrderColor
      ..style = PaintingStyle.fill;

    final medians = [
      for (final median in glyph.medians)
        [for (final (x, y) in median) _toBox(x, y, side)],
    ];

    // Lines and arrows first, then every badge on top of them.
    for (final points in medians) {
      if (points.length < 2) continue;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);
      _paintArrowhead(canvas, points, side, solid);
    }

    final radius = math.max(7.0, side * 0.03);
    final placed = <Offset>[];
    for (var i = 0; i < medians.length; i++) {
      final points = medians[i];
      if (points.isEmpty) continue;
      final centre = _badgeCentre(points, radius, side, placed);
      placed.add(centre);
      canvas.drawCircle(centre, radius, solid);
      _paintNumber(canvas, '${i + 1}', centre, radius);
    }
  }

  void _paintGuide(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = guideColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), guide);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), guide);
    canvas.drawLine(Offset.zero, Offset(w, h), guide);
    canvas.drawLine(Offset(w, 0), Offset(0, h), guide);
  }

  /// A filled triangle at the end of the centre line, pointing the way the
  /// stroke travels. The direction is taken from a point a little way back
  /// along the line, since the last segment can be very short.
  void _paintArrowhead(
      Canvas canvas, List<Offset> points, double side, Paint paint) {
    final end = points.last;
    final direction = _direction(
        points.reversed.skip(1), end, side * 0.04, fallbackFrom: points.first);
    if (direction == null) return;
    final length = math.max(6.0, side * 0.045);
    Offset wing(double angle) {
      final back = _rotate(-direction, angle);
      return end + back * length;
    }

    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(wing(0.45).dx, wing(0.45).dy)
      ..lineTo(wing(-0.45).dx, wing(-0.45).dy)
      ..close();
    canvas.drawPath(arrow, paint);
  }

  /// Where a stroke's number goes: just before the point where the pen goes
  /// down, back along the stroke's starting direction, as in a textbook.
  /// Nudged further back if it would sit on a badge already placed (two
  /// strokes of 口 start at the same corner), and kept inside the box.
  Offset _badgeCentre(
      List<Offset> points, double radius, double side, List<Offset> placed) {
    final start = points.first;
    // Points from further along the stroke back towards its start, i.e.
    // against the direction of travel.
    final back = _direction(points.skip(1), start, side * 0.02,
            fallbackFrom: points.last) ??
        const Offset(-1, 0);
    var centre = start + back * (radius * 1.3);
    for (var tries = 0; tries < 3; tries++) {
      final clash = placed.any((p) => (p - centre).distance < radius * 1.9);
      if (!clash) break;
      centre += back * (radius * 2);
    }
    return Offset(
      centre.dx.clamp(radius, side - radius).toDouble(),
      centre.dy.clamp(radius, side - radius).toDouble(),
    );
  }

  void _paintNumber(Canvas canvas, String text, Offset centre, double radius) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: onStrokeOrderColor,
          fontSize: text.length > 1 ? radius * 1.05 : radius * 1.3,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant WritingGuidePainter oldDelegate) =>
      oldDelegate.reference != reference ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.strokeOrderColor != strokeOrderColor ||
      oldDelegate.onStrokeOrderColor != onStrokeOrderColor;
}

/// The unit vector from the first of [others] at least [minDistance] away
/// from [anchor], towards [anchor]. Falls back to [fallbackFrom] if none is
/// that far; null if even that coincides with [anchor].
Offset? _direction(Iterable<Offset> others, Offset anchor, double minDistance,
    {required Offset fallbackFrom}) {
  var from = fallbackFrom;
  for (final p in others) {
    if ((anchor - p).distance >= minDistance) {
      from = p;
      break;
    }
  }
  final v = anchor - from;
  final length = v.distance;
  if (length == 0) return null;
  return v / length;
}

Offset _rotate(Offset v, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
}

Offset _toBox(double x, double y, double size) {
  final (bx, by) = StrokeReference.toBox(x, y, size);
  return Offset(bx, by);
}

/// One reference stroke's outline as a [Path], placed in a square box
/// [size] pixels wide (see [StrokeReference.toBox]).
Path glyphStrokePath(GlyphStroke stroke, double size) {
  final path = Path();
  for (final command in stroke) {
    final c = command.coords;
    final points = <Offset>[];
    for (var i = 0; i + 1 < c.length; i += 2) {
      points.add(_toBox(c[i], c[i + 1], size));
    }
    switch (command.op) {
      case 'M':
        path.moveTo(points[0].dx, points[0].dy);
      case 'L':
        path.lineTo(points[0].dx, points[0].dy);
      case 'Q':
        path.quadraticBezierTo(
            points[0].dx, points[0].dy, points[1].dx, points[1].dy);
      case 'C':
        path.cubicTo(points[0].dx, points[0].dy, points[1].dx, points[1].dy,
            points[2].dx, points[2].dy);
      case 'Z':
        path.close();
    }
  }
  return path;
}
