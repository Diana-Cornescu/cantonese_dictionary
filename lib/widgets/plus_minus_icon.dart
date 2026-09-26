import 'package:flutter/material.dart';

/// A "+/−" icon: a plus, a slash and a minus in one row, like the text
/// "+/−" (2026-09-26; the first version stacked them diagonally, which
/// looked squished). Used for "add or remove" buttons (2026-09-26): linking characters
/// to a photo, characters to a tag, and tags to a character. One button
/// does both, and the icon says so, where a plain + suggested it could
/// only add.
///
/// Drawn in code, like `LanguageIcon`, and colored and sized from the
/// surrounding [IconTheme] exactly like an [Icon], so it drops into any
/// button. On a 24 × 24 grid, the same as Material icons.
class PlusMinusIcon extends StatelessWidget {
  const PlusMinusIcon({super.key, this.size, this.color});

  /// Defaults to the [IconTheme]'s size, like [Icon].
  final double? size;

  /// Defaults to the [IconTheme]'s color, like [Icon].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final side = size ?? iconTheme.size ?? 24;
    final ink =
        color ?? iconTheme.color ?? DefaultTextStyle.of(context).style.color;
    return Semantics(
      label: 'Add or remove',
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(painter: _PlusMinusPainter(ink)),
      ),
    );
  }
}

class _PlusMinusPainter extends CustomPainter {
  _PlusMinusPainter(this.color);

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = color;
    if (ink == null) return;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // Plus, on the left.
    canvas.drawLine(const Offset(1.5, 12), const Offset(8.5, 12), pen);
    canvas.drawLine(const Offset(5, 8.5), const Offset(5, 15.5), pen);
    // Minus, on the right, level with the plus.
    canvas.drawLine(const Offset(15.5, 12), const Offset(22.5, 12), pen);
    // The slash between them, thinner so the signs stay the focus.
    canvas.drawLine(
      const Offset(13.8, 7),
      const Offset(10.2, 17),
      pen..strokeWidth = 1.6,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlusMinusPainter old) => old.color != color;
}
