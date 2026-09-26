import 'package:flutter/material.dart';

import '../data/stroke_reference.dart';

/// Paints the background of a Write-tab box: a faint 米字格 guide (a cross
/// and both diagonals, to help with proportions) and, once you've tapped
/// Check, the correct form of the character filled in underneath your ink.
///
/// Used as `HandwritingCanvas.backgroundPainter`, so it sits on the paper
/// and under the strokes. Expects a square box; the reference is scaled to
/// the box's width.
class WritingGuidePainter extends CustomPainter {
  WritingGuidePainter({
    required this.guideColor,
    this.reference,
    this.referenceColor,
  });

  final Color guideColor;

  /// The character's strokes from [StrokeReference], or null to show only
  /// the guide.
  final List<GlyphStroke>? reference;

  /// Fill color for [reference]. Required when [reference] is set.
  final Color? referenceColor;

  @override
  void paint(Canvas canvas, Size size) {
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

    final strokes = reference;
    final color = referenceColor;
    if (strokes == null || color == null) return;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final stroke in strokes) {
      canvas.drawPath(glyphStrokePath(stroke, w), fill);
    }
  }

  @override
  bool shouldRepaint(covariant WritingGuidePainter oldDelegate) =>
      oldDelegate.reference != reference ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.referenceColor != referenceColor;
}

/// One reference stroke's outline as a [Path], placed in a square box
/// [size] pixels wide (see [StrokeReference.toBox]).
Path glyphStrokePath(GlyphStroke stroke, double size) {
  final path = Path();
  for (final command in stroke) {
    final c = command.coords;
    final points = <Offset>[];
    for (var i = 0; i + 1 < c.length; i += 2) {
      final (x, y) = StrokeReference.toBox(c[i], c[i + 1], size);
      points.add(Offset(x, y));
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
