import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/core/widgets/signature_pad.dart';

/// The pad lives inside a scrolling card on Vehicle Information, so these
/// tests pump it inside a ListView on purpose: a vertical stroke used to be
/// claimed by the scroll view, which is what made signing look broken.
Widget _wrap(Widget pad) => MaterialApp(
  home: Scaffold(
    body: ListView(
      children: [const SizedBox(height: 400), pad, const SizedBox(height: 800)],
    ),
  ),
);

void main() {
  testWidgets('a stroke drawn inside a scroll view reaches the pad', (
    tester,
  ) async {
    Uint8List? emitted;
    final controller = SignaturePadController();

    await tester.pumpWidget(
      _wrap(
        SignaturePad(
          controller: controller,
          onChanged: (bytes) => emitted = bytes,
        ),
      ),
    );

    final pad = find.byType(SignaturePad);
    final centre = tester.getCenter(pad);

    // A mostly-vertical drag -- the exact gesture the ListView used to steal.
    final gesture = await tester.startGesture(centre - const Offset(30, 20));
    await gesture.moveBy(const Offset(20, 40));
    await gesture.moveBy(const Offset(25, -10));
    await gesture.up();
    await tester.pumpAndSettle();

    // The ink landed on the pad rather than scrolling the list.
    expect(controller.isEmpty, isFalse);
    // Placeholder is gone once there is ink on the pad.
    expect(find.text('Please sign in this field'), findsNothing);

    // Exporting the PNG goes through the engine, so it needs real async time
    // -- `emitted` is filled in a beat after the gesture, not during pump.
    final exported = await tester.runAsync(controller.export);
    expect(exported, isNotNull, reason: 'the stroke should be exportable');
    expect(emitted, isNotNull, reason: 'the stroke should have been reported');
  });

  testWidgets('the list still scrolls when the drag starts outside the pad', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(SignaturePad(onChanged: (_) {})));

    final before = tester.getTopLeft(find.byType(SignaturePad)).dy;
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();

    expect(tester.getTopLeft(find.byType(SignaturePad)).dy, lessThan(before));
  });

  testWidgets('controller.clear wipes the ink and reports null', (
    tester,
  ) async {
    Uint8List? emitted;
    final controller = SignaturePadController();

    await tester.pumpWidget(
      _wrap(
        SignaturePad(
          controller: controller,
          onChanged: (bytes) => emitted = bytes,
        ),
      ),
    );

    final centre = tester.getCenter(find.byType(SignaturePad));
    final gesture = await tester.startGesture(centre);
    await gesture.moveBy(const Offset(40, 30));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.runAsync(controller.export);
    expect(controller.isEmpty, isFalse);
    emitted = Uint8List(0); // stand in for "something was signed"

    controller.clear();
    await tester.pumpAndSettle();

    expect(emitted, isNull);
    expect(controller.isEmpty, isTrue);
    expect(find.text('Please sign in this field'), findsOneWidget);
  });

  testWidgets('a disabled pad ignores strokes', (tester) async {
    Uint8List? emitted;

    await tester.pumpWidget(
      _wrap(
        SignaturePad(enabled: false, onChanged: (bytes) => emitted = bytes),
      ),
    );

    final centre = tester.getCenter(find.byType(SignaturePad));
    final gesture = await tester.startGesture(centre);
    await gesture.moveBy(const Offset(40, 30));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(emitted, isNull);
    expect(find.text('Please sign in this field'), findsOneWidget);
  });
}
