import 'package:flutter/material.dart';

import '../data/character_entry.dart';

/// A canvas for capturing or displaying a single handwritten character
/// sample, selected by the [readOnly] constructor flag:
///
///  - Draw mode (`readOnly: false`): captures pointer drags into strokes
///    and reports the full stroke list via [onStrokesChanged] once a
///    stroke ends. This widget does not keep drawing history itself and
///    has no built-in "clear"/"save" buttons — whoever owns the data
///    (Phase 2's add/detail screens, via `DictionaryStore`) decides when a
///    redraw should replace the previous sample and wires up any buttons.
///  - Read-only mode (`readOnly: true`): paints [initialStrokes] and
///    ignores all pointer input.
class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({
    super.key,
    required this.readOnly,
    this.initialStrokes,
    this.onStrokesChanged,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4.0,
  });

  final bool readOnly;

  /// Stroke data to render (read-only mode) or start from (draw mode).
  final List<List<StrokePoint>>? initialStrokes;

  /// Called with the complete stroke list after each stroke finishes.
  /// Ignored in read-only mode.
  final ValueChanged<List<List<StrokePoint>>>? onStrokesChanged;

  final Color strokeColor;
  final double strokeWidth;

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  late List<List<StrokePoint>> _strokes;

  @override
  void initState() {
    super.initState();
    _strokes = _cloneStrokes(widget.initialStrokes);
  }

  @override
  void didUpdateWidget(covariant HandwritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readOnly && widget.initialStrokes != oldWidget.initialStrokes) {
      _strokes = _cloneStrokes(widget.initialStrokes);
    }
  }

  List<List<StrokePoint>> _cloneStrokes(List<List<StrokePoint>>? source) {
    if (source == null) return [];
    return source.map((stroke) => List<StrokePoint>.from(stroke)).toList();
  }

  StrokePoint _pointFrom(Offset offset) {
    return StrokePoint(
      x: offset.dx,
      y: offset.dy,
      t: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.readOnly) return;
    setState(() {
      _strokes.add([_pointFrom(details.localPosition)]);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.readOnly || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(_pointFrom(details.localPosition));
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.readOnly) return;
    widget.onStrokesChanged?.call(_cloneStrokes(_strokes));
  }

  @override
  Widget build(BuildContext context) {
    final painter = _StrokesPainter(
      strokes: _strokes,
      color: widget.strokeColor,
      strokeWidth: widget.strokeWidth,
    );
    final canvas = CustomPaint(painter: painter, size: Size.infinite);
    if (widget.readOnly) {
      return canvas;
    }
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: canvas,
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  final List<List<StrokePoint>> strokes;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke[0].x, stroke[0].y),
          strokeWidth / 2,
          dotPaint,
        );
        continue;
      }
      final path = Path()..moveTo(stroke[0].x, stroke[0].y);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].x, stroke[i].y);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  // Always repaint: strokes are mutated in place while drawing (points are
  // appended to the last stroke's list without changing the outer list's
  // identity), so an identity/equality check here could miss in-progress
  // strokes. Repaint cost is negligible for a single small canvas.
  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}
