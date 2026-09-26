import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which language emblem [LanguageIcon] draws.
enum LanguageEmblem {
  /// Five stars: one large, four small ones turned towards it.
  mandarin,

  /// A five-petal bauhinia flower, petals swirling round the centre.
  cantonese,
}

/// A small one-color emblem for the Cantonese and Mandarin buttons
/// (2026-09-26): a bauhinia flower for Cantonese, five stars for Mandarin.
///
/// Drawn in code rather than from an image, so it stays sharp at any size
/// and takes its color from the surrounding [IconTheme] exactly like a
/// normal [Icon] does: black in light mode and white in dark mode when the
/// button is on, grey when it's off. It holds no color of its own, which
/// also keeps it clear of `test/no_hardcoded_colors_test.dart`.
///
/// Shapes are laid out on a 24 × 24 grid, the same as Material icons.
class LanguageIcon extends StatelessWidget {
  const LanguageIcon(this.emblem, {super.key, this.size, this.color});

  final LanguageEmblem emblem;

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
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _EmblemPainter(emblem, ink),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.emblem, this.color);

  final LanguageEmblem emblem;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = color;
    if (fill == null) return;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final path = switch (emblem) {
      LanguageEmblem.mandarin => _stars(),
      LanguageEmblem.cantonese => _bauhinia(),
    };
    canvas.drawPath(
      path,
      Paint()
        ..color = fill
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.emblem != emblem || old.color != color;

  /// A five-pointed star centred on ([cx], [cy]) with outer radius [r],
  /// its first point facing [aim] (radians, 0 = right, clockwise).
  static void _addStar(Path path, double cx, double cy, double r, double aim) {
    const innerRatio = 0.382;
    for (var i = 0; i < 10; i++) {
      final angle = aim + i * math.pi / 5;
      final radius = i.isEven ? r : r * innerRatio;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  /// One large star on the left and four small ones in an arc to its
  /// right, each small one pointing at the large one.
  static Path _stars() {
    final path = Path();
    const bigX = 8.5, bigY = 11.5;
    _addStar(path, bigX, bigY, 6.2, -math.pi / 2);
    const small = [(16.8, 4.6), (20.6, 8.8), (20.6, 14.4), (16.8, 18.6)];
    for (final (x, y) in small) {
      _addStar(path, x, y, 2.8, math.atan2(bigY - y, bigX - x));
    }
    return path;
  }

  /// One petal, pointing up from the centre, as cubic curves relative to
  /// the middle of the flower: a rounded crown with a hooked tip on the
  /// right, which is what makes the five of them swirl.
  static const _petalStart = Offset(0.8, -1.2);
  static const _petalCurves = [
    [Offset(-3.6, -2.8), Offset(-6.0, -6.8), Offset(-4.8, -9.6)],
    [Offset(-3.6, -12.0), Offset(0.4, -12.4), Offset(2.8, -10.6)],
    [Offset(1.3, -10.3), Offset(0.5, -9.3), Offset(1.0, -7.8)],
    [Offset(1.7, -5.4), Offset(2.0, -3.0), Offset(0.8, -1.2)],
  ];

  /// Five petals round (12, 12), 72° apart.
  static Path _bauhinia() {
    final path = Path();
    const centre = Offset(12, 12);
    for (var k = 0; k < 5; k++) {
      final angle = k * 2 * math.pi / 5;
      final cosA = math.cos(angle), sinA = math.sin(angle);
      Offset place(Offset p) =>
          centre + Offset(p.dx * cosA - p.dy * sinA, p.dx * sinA + p.dy * cosA);
      final start = place(_petalStart);
      path.moveTo(start.dx, start.dy);
      for (final curve in _petalCurves) {
        final a = place(curve[0]), b = place(curve[1]), c = place(curve[2]);
        path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
      }
      path.close();
    }
    return path;
  }
}
