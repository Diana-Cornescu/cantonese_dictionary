import 'package:flutter/material.dart';

import '../data/character_entry.dart';
import '../theme/app_color_roles.dart';
import 'ink_settings.dart';

/// A canvas for capturing or displaying a single handwritten character
/// sample, selected by the [readOnly] constructor flag:
///
///  - Draw mode (`readOnly: false`): captures pointer drags into strokes
///    and reports the full stroke list via [onStrokesChanged] once a
///    stroke ends. Two small buttons in the top-right corner let you
///    **undo the last stroke** or **clear** the whole drawing without
///    leaving the window (added 2026-09-20); both also report the new
///    stroke list via [onStrokesChanged]. Saving is still up to the screen
///    that owns the data.
///  - Read-only mode (`readOnly: true`): paints [initialStrokes] and
///    ignores all pointer input.
///
/// Either mode can paint a [backgroundPainter] on the paper, under the
/// ink: the Write tab's guide lines and reference character (2026-09-25).
///
/// **Pen size and smoothing** come from Settings → Handwriting via
/// [InkSettings.of] (2026-09-26), in both modes, so they apply to every
/// drawing in the app. They only change how the ink is *drawn*; the points
/// recorded and saved are the same either way.
class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({
    super.key,
    required this.readOnly,
    this.initialStrokes,
    this.onStrokesChanged,
    this.strokeColor,
    this.strokeWidth,
    this.fitToBox = false,
    this.backgroundPainter,
  });

  final bool readOnly;

  /// Read-only mode only: scale and center the drawing to fill this
  /// widget's box, instead of painting at the original drawing's pixel
  /// positions. Used for small previews (e.g. the flashcard answer), which
  /// are smaller than the box the character was drawn in.
  final bool fitToBox;

  /// Stroke data to render (read-only mode) or start from (draw mode).
  final List<List<StrokePoint>>? initialStrokes;

  /// Called with the complete stroke list after each stroke finishes.
  /// Ignored in read-only mode.
  final ValueChanged<List<List<StrokePoint>>>? onStrokesChanged;

  /// Defaults to the theme's ink color (`context.appColors.ink`).
  final Color? strokeColor;

  /// Overrides the pen size from Settings. Only the Settings preview uses
  /// it, to show the size being dragged before it's saved.
  final double? strokeWidth;

  /// Painted on the paper, under the strokes. Not scaled by [fitToBox].
  final CustomPainter? backgroundPainter;

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

  /// Removes the most recent stroke.
  void _undoLastStroke() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onStrokesChanged?.call(_cloneStrokes(_strokes));
  }

  /// Removes every stroke.
  void _clearAll() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.clear());
    widget.onStrokesChanged?.call(_cloneStrokes(_strokes));
  }

  @override
  Widget build(BuildContext context) {
    final ink = InkSettings.of(context);
    final painter = _StrokesPainter(
      strokes: _strokes,
      color: widget.strokeColor ?? context.appColors.ink,
      strokeWidth: widget.strokeWidth ?? ink.width,
      smooth: ink.smooth,
      fitToBox: widget.readOnly && widget.fitToBox,
    );
    // Clipped to its own bounds: on desktop a drag can carry the pointer
    // past the widget's edge while still held down, which would otherwise
    // let the stroke paint outside the box into whatever sits next to it.
    // The underlying point data is unaffected — only the on-screen paint is
    // constrained.
    //
    // Drawn on `paper`: see-through in light mode, a light sheet in dark
    // mode, so black ink reads the same in both (2026-09-25).
    final colors = context.appColors;
    final canvas = ClipRect(
      child: ColoredBox(
        color: colors.paper,
        child: CustomPaint(
          painter: widget.backgroundPainter,
          foregroundPainter: painter,
          size: Size.infinite,
        ),
      ),
    );
    if (widget.readOnly) {
      return canvas;
    }
    final hasStrokes = _strokes.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: canvas,
          ),
        ),
        // Undo / clear, kept small in the corner so they don't take space
        // away from the drawing area.
        Positioned(
          top: 2,
          right: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Undo last stroke',
                visualDensity: VisualDensity.compact,
                // On the paper, not the page: the theme's icon grey would
                // disappear on the light sheet in dark mode.
                color: colors.onPaper,
                disabledColor: colors.onPaper.withValues(alpha: 0.38),
                icon: const Icon(Icons.undo),
                onPressed: hasStrokes ? _undoLastStroke : null,
              ),
              IconButton(
                tooltip: 'Clear drawing',
                visualDensity: VisualDensity.compact,
                color: colors.onPaper,
                disabledColor: colors.onPaper.withValues(alpha: 0.38),
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: hasStrokes ? _clearAll : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    required this.smooth,
    this.fitToBox = false,
  });

  final List<List<StrokePoint>> strokes;
  final Color color;
  final double strokeWidth;
  final bool smooth;
  final bool fitToBox;

  /// Scales and centers the drawing's bounding box inside [size], keeping
  /// its proportions and leaving a small margin. Only used when [fitToBox].
  /// Returns the scale factor applied (1.0 if nothing was drawn).
  double _applyFit(Canvas canvas, Size size) {
    double? minX, minY, maxX, maxY;
    for (final stroke in strokes) {
      for (final p in stroke) {
        minX = minX == null || p.x < minX ? p.x : minX;
        minY = minY == null || p.y < minY ? p.y : minY;
        maxX = maxX == null || p.x > maxX ? p.x : maxX;
        maxY = maxY == null || p.y > maxY ? p.y : maxY;
      }
    }
    if (minX == null || minY == null || maxX == null || maxY == null) {
      return 1.0;
    }
    final margin = strokeWidth * 2;
    final width = (maxX - minX).clamp(1.0, double.infinity);
    final height = (maxY - minY).clamp(1.0, double.infinity);
    final scale = [
      (size.width - margin * 2) / width,
      (size.height - margin * 2) / height,
    ].reduce((a, b) => a < b ? a : b);
    final dx = (size.width - width * scale) / 2 - minX * scale;
    final dy = (size.height - height * scale) / 2 - minY * scale;
    canvas.translate(dx, dy);
    canvas.scale(scale);
    return scale;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var drawWidth = strokeWidth;
    if (fitToBox) {
      canvas.save();
      final scale = _applyFit(canvas, size);
      // Keep the line thickness looking the same after scaling.
      if (scale > 0) drawWidth = strokeWidth / scale;
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = drawWidth
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
          drawWidth / 2,
          dotPaint,
        );
        continue;
      }
      canvas.drawPath(inkPath(stroke, smooth: smooth), linePaint);
    }
    if (fitToBox) canvas.restore();
  }

  // Always repaint: strokes are mutated in place while drawing (points are
  // appended to the last stroke's list without changing the outer list's
  // identity), so an identity/equality check here could miss in-progress
  // strokes. Repaint cost is negligible for a single small canvas.
  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}

/// One stroke as a [Path] (it needs at least two points).
///
/// Straight segments between the recorded points, or with [smooth] a
/// curve through them: each point becomes the control point of a
/// quadratic curve between the midpoints on either side of it, so the
/// line still starts and ends exactly where the pen did but corners and
/// finger jitter are rounded off. Cheap enough to redo on every frame.
Path inkPath(List<StrokePoint> stroke, {required bool smooth}) {
  final path = Path()..moveTo(stroke[0].x, stroke[0].y);
  if (!smooth || stroke.length < 3) {
    for (var i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].x, stroke[i].y);
    }
    return path;
  }
  for (var i = 1; i < stroke.length - 1; i++) {
    final p = stroke[i];
    final next = stroke[i + 1];
    path.quadraticBezierTo(p.x, p.y, (p.x + next.x) / 2, (p.y + next.y) / 2);
  }
  path.lineTo(stroke.last.x, stroke.last.y);
  return path;
}
