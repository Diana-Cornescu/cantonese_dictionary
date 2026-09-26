import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/stroke_reference.dart';

/// Paints the background of a Write-tab box: a faint 米字格 guide (a cross
/// and both diagonals, to help with proportions) and, when [reference] is
/// set, the character's **X-ray** underneath your ink:
///  - each stroke's outline, filled in pale grey,
///  - its centre line, with an **arrowhead** where the pen lifts, so you
///    can see the direction,
///  - a numbered **badge** on that line, a short way in from where the pen
///    goes down: 1, 2, 3… in stroke order.
///
/// The Write tab shows it from the start, to write over (2026-09-26), with
/// [activeStroke] highlighting the stroke to write next: its line, arrow
/// and badge in [strokeOrderColor], every other stroke's in [mutedColor].
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
    required this.mutedColor,
    this.reference,
    this.activeStroke,
  });

  final Color guideColor;

  /// The character's reference form, or null to show only the guide.
  final ReferenceGlyph? reference;

  /// Which stroke (0-based) to highlight, or null to show every stroke in
  /// [strokeOrderColor]. At or past the last stroke (the character is
  /// finished) everything is shown in [strokeOrderColor] again.
  final int? activeStroke;

  /// Fill for the stroke outlines.
  final Color outlineColor;

  /// The centre lines, arrowheads and number badges…
  final Color strokeOrderColor;

  /// …and the numbers inside the badges, and the ring around each badge.
  final Color onStrokeOrderColor;

  /// Lines, arrows and badges of the strokes that aren't highlighted.
  final Color mutedColor;

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

    final medians = [
      for (final median in glyph.medians)
        [for (final (x, y) in median) _toBox(x, y, side)],
    ];
    final active = activeStroke;
    final highlighting = active != null && active < medians.length;
    bool isMuted(int i) => highlighting && i != active;

    // Muted strokes first, so the highlighted one is drawn over them where
    // they cross; within each group, lines and arrows before badges.
    final order = [
      for (var i = 0; i < medians.length; i++)
        if (isMuted(i)) i,
      for (var i = 0; i < medians.length; i++)
        if (!isMuted(i)) i,
    ];
    final lineWidth = math.max(1.5, side * 0.012);
    for (final i in order) {
      final points = medians[i];
      if (points.length < 2) continue;
      final color = isMuted(i) ? mutedColor : strokeOrderColor;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      _paintArrowhead(canvas, points, side, Paint()..color = color);
    }

    // Badge positions are worked out in stroke order, so the nudging is
    // the same whichever stroke is highlighted; then drawn muted-first.
    final radius = math.max(7.0, side * 0.03);
    final centres = <int, Offset>{};
    for (var i = 0; i < medians.length; i++) {
      if (medians[i].isEmpty) continue;
      centres[i] =
          _badgeCentre(medians[i], radius, side, centres.values.toList());
    }
    for (final i in order) {
      final centre = centres[i];
      if (centre == null) continue;
      // A ring in the number's color keeps the badge readable where it
      // sits on top of another stroke's line.
      canvas.drawCircle(
          centre, radius + 1.5, Paint()..color = onStrokeOrderColor);
      canvas.drawCircle(centre, radius,
          Paint()..color = isMuted(i) ? mutedColor : strokeOrderColor);
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
    canvas.drawPath(arrow, paint..style = PaintingStyle.fill);
  }

  /// Where a stroke's number goes: **on its own centre line**, a short way
  /// in from where the pen goes down (2026-09-26). A badge sitting on a
  /// line plainly belongs to that line, and strokes that start at the same
  /// point (目's first two, at the top-left corner) separate as soon as
  /// they head off in different directions. If it would still touch a
  /// badge already placed, it slides further along its own stroke.
  ///
  /// (The first version put it just *before* the start, off the stroke,
  /// which left it ambiguous at shared corners and crossings.)
  Offset _badgeCentre(
      List<Offset> points, double radius, double side, List<Offset> placed) {
    final length = _pathLength(points);
    if (length == 0) return points.first;
    var fraction = math.min(0.3, radius * 2.2 / length);
    var centre = _pointAlong(points, length * fraction);
    for (var tries = 0; tries < 4; tries++) {
      final clash = placed.any((p) => (p - centre).distance < radius * 2);
      if (!clash) break;
      fraction = math.min(0.9, fraction + 0.12);
      centre = _pointAlong(points, length * fraction);
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
      oldDelegate.activeStroke != activeStroke ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.strokeOrderColor != strokeOrderColor ||
      oldDelegate.onStrokeOrderColor != onStrokeOrderColor ||
      oldDelegate.mutedColor != mutedColor;
}

double _pathLength(List<Offset> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += (points[i] - points[i - 1]).distance;
  }
  return total;
}

/// The point [distance] along the polyline [points] from its start.
Offset _pointAlong(List<Offset> points, double distance) {
  var travelled = 0.0;
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final segment = (b - a).distance;
    if (segment > 0 && travelled + segment >= distance) {
      return Offset.lerp(a, b, (distance - travelled) / segment)!;
    }
    travelled += segment;
  }
  return points.last;
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
