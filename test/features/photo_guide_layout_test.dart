import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/features/preinspection_agent/presentation/add_others_photos/add_others_photos_page.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/presentation/photo_capture_selection/photo_capture_selection_page.dart';

const _captions = [
  'Front',
  'Front RH',
  'RH Side',
  'Rear RH',
  'Rear',
  'Rear LH',
  'LH Side',
  'Front LH',
];

Future<void> _pumpGuide(WidgetTester tester, Size logicalSize) async {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: PhotoCaptureSelectionPage())),
  );
  await tester.pump();
}

void main() {
  // A typical phone in landscape, and a small one.
  for (final size in const [Size(900, 412), Size(740, 360)]) {
    group('photo guide at ${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('each side sits where it is on the vehicle', (tester) async {
        await _pumpGuide(tester, size);

        final vehicle = tester.getRect(find.byType(Image).first);
        final c = vehicle.center;
        Offset at(String caption) => tester.getCenter(find.text(caption));

        // The centre art is a front-left three-quarter view: front to the
        // lower left, rear to the upper right, left side facing the viewer.
        expect(at('Front').dx, lessThan(c.dx), reason: 'front is on the left');
        expect(at('Front').dy, greaterThan(c.dy), reason: 'front is low');
        expect(
          at('Rear').dx,
          greaterThan(c.dx),
          reason: 'rear is on the right',
        );
        expect(at('Rear').dy, lessThan(c.dy), reason: 'rear is high');
        expect(
          at('LH Side').dx,
          greaterThan(c.dx),
          reason: 'visible LH side runs to the right',
        );
        expect(
          at('LH Side').dy,
          greaterThan(c.dy),
          reason: 'visible LH side is near the viewer',
        );
        expect(
          at('RH Side').dx,
          lessThan(c.dx),
          reason: 'hidden RH side is behind, to the left',
        );
        expect(
          at('RH Side').dy,
          lessThan(c.dy),
          reason: 'hidden RH side is behind the roof',
        );

        // Corners sit between the faces they join.
        expect(at('Front RH').dx, lessThan(at('Front').dx));
        expect(at('Rear LH').dx, greaterThan(at('Rear').dx));
        expect(at('Front LH').dy, greaterThan(c.dy));
        expect(at('Rear RH').dy, lessThan(c.dy));
      });

      testWidgets('no caption overlaps another caption or the vehicle', (
        tester,
      ) async {
        await _pumpGuide(tester, size);

        final vehicle = tester.getRect(find.byType(Image).first);
        final rects = {
          for (final caption in _captions)
            caption: _textBounds(tester, caption),
        };

        for (final a in _captions) {
          expect(
            rects[a]!.overlaps(vehicle.deflate(vehicle.shortestSide * 0.12)),
            isFalse,
            reason: '"$a" caption runs into the vehicle',
          );
          for (final b in _captions) {
            if (a.compareTo(b) >= 0) continue;
            expect(
              rects[a]!.overlaps(rects[b]!),
              isFalse,
              reason: '"$a" overlaps "$b"',
            );
          }
        }
      });

      testWidgets('everything fits on screen', (tester) async {
        await _pumpGuide(tester, size);
        final screen = Offset.zero & size;
        for (final caption in _captions) {
          final r = _textBounds(tester, caption);
          expect(
            screen.contains(r.topLeft) && screen.contains(r.bottomRight),
            isTrue,
            reason: '"$caption" is clipped',
          );
        }
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets(
    'add others photos: sample and capture frames are the same size',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AddOthersPhotosPage())),
      );
      await tester.pump();

      final sample = tester.getRect(find.byType(AspectRatio).at(0));
      final capture = tester.getRect(find.byType(AspectRatio).at(1));

      expect(sample.size, capture.size);
      expect(sample.top, capture.top, reason: 'the two halves line up');
      expect(capture.left, greaterThan(sample.right), reason: 'side by side');
      expect(tester.takeException(), isNull);
    },
  );
}

/// Bounds of the glyphs actually drawn for [caption] (the caption box is
/// wider than its text, so its layout rect would over-report overlaps).
Rect _textBounds(WidgetTester tester, String caption) {
  final box = tester.getRect(find.text(caption));
  final render = tester.renderObject<RenderParagraph>(find.text(caption));
  final width = render.getMaxIntrinsicWidth(double.infinity);
  return Rect.fromCenter(center: box.center, width: width, height: box.height);
}
