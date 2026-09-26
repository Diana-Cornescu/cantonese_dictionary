import 'package:cantonese_dictionary_app/data/character_entry.dart';
import 'package:cantonese_dictionary_app/widgets/handwriting_canvas.dart';
import 'package:cantonese_dictionary_app/widgets/ink_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pen size and smoothing (Settings → Handwriting, 2026-09-26).
void main() {
  group('reading the stored settings', () {
    test('the keys are stable', () {
      // Saved in the settings table under these names; renaming one would
      // silently reset everyone's choice.
      expect(InkSettings.widthKey, 'ink_width');
      expect(InkSettings.smoothKey, 'ink_smoothing');
    });

    test('never set means 4 px and smoothed', () {
      final ink = InkSettings.fromStored(null, null);
      expect(ink.width, 4);
      expect(ink.smooth, isTrue);
      expect(ink, const InkSettings());
    });

    test('reads a saved size and switch', () {
      final ink = InkSettings.fromStored('6', 'false');
      expect(ink.width, 6);
      expect(ink.smooth, isFalse);
      expect(InkSettings.fromStored('10', 'true').smooth, isTrue);
    });

    test('a size outside 2–10 is clamped; junk falls back to 4', () {
      expect(InkSettings.maxWidth, 10);
      expect(InkSettings.fromStored('30', null).width, 10);
      expect(InkSettings.fromStored('0', null).width, InkSettings.minWidth);
      expect(InkSettings.fromStored('big', null).width, 4);
      expect(InkSettings.fromStored('NaN', null).width, 4);
      // Only an explicit 'false' turns smoothing off.
      expect(InkSettings.fromStored(null, 'yes').smooth, isTrue);
    });
  });

  group('drawing a stroke', () {
    const zigzag = [
      StrokePoint(x: 0, y: 0, t: 0),
      StrokePoint(x: 10, y: 20, t: 0),
      StrokePoint(x: 20, y: 0, t: 0),
      StrokePoint(x: 30, y: 20, t: 0),
    ];

    test('smoothing keeps where the stroke starts and ends', () {
      final smooth = inkPath(zigzag, smooth: true);
      final bounds = smooth.getBounds();
      expect(bounds.left, 0);
      expect(bounds.right, 30);
      // It starts at the first point and ends at the last.
      final metric = smooth.computeMetrics().single;
      final start = metric.getTangentForOffset(0)!.position;
      final end = metric.getTangentForOffset(metric.length)!.position;
      expect(start.dx, closeTo(0, 0.01));
      expect(start.dy, closeTo(0, 0.01));
      expect(end.dx, closeTo(30, 0.01));
      expect(end.dy, closeTo(20, 0.01));
    });

    test('smoothing rounds the corners off, so the line is shorter', () {
      final straight = inkPath(zigzag, smooth: false).computeMetrics().single;
      final smooth = inkPath(zigzag, smooth: true).computeMetrics().single;
      expect(smooth.length, lessThan(straight.length));
    });

    test('two points stay a straight line either way', () {
      const line = [
        StrokePoint(x: 0, y: 0, t: 0),
        StrokePoint(x: 40, y: 0, t: 0),
      ];
      expect(inkPath(line, smooth: true).computeMetrics().single.length,
          closeTo(40, 0.01));
    });
  });
}
