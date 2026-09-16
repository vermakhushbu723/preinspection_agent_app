import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/features/preinspection_agent/data/vehicle_catalog.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/presentation/owner_vehicle_details/owner_vehicle_details_page.dart';

const _idvLabel = 'Present Market Value (Estimated)/ IDV';

Future<void> _pumpPage(WidgetTester tester) async {
  // Tall enough that the whole form is built without scrolling.
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: OwnerVehicleDetailsPage())),
  );
  await tester.pumpAndSettle();
}

/// Opens the dropdown currently showing [hint] and picks [item].
Future<void> _choose(WidgetTester tester, String hint, String item) async {
  await tester.tap(find.text(hint));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

String _idvText(WidgetTester tester) {
  final field = find
      .ancestor(of: find.text(_idvLabel), matching: find.byType(Column))
      .first;
  final textField = tester.widget<TextField>(
    find.descendant(of: field, matching: find.byType(TextField)),
  );
  return textField.controller!.text;
}

void main() {
  testWidgets('market value is only asked for on a valuation survey', (
    tester,
  ) async {
    await _pumpPage(tester);

    // Pre inspection is the default -- no market value field.
    expect(find.text(_idvLabel), findsNothing);

    await tester.tap(find.text('Valuation'));
    await tester.pumpAndSettle();
    expect(find.text(_idvLabel), findsOneWidget);

    await tester.tap(find.text('pre inspection'));
    await tester.pumpAndSettle();
    expect(find.text(_idvLabel), findsNothing);
  });

  testWidgets('choosing a make resets the model and variant under it', (
    tester,
  ) async {
    await _pumpPage(tester);

    await _choose(tester, 'Select product', 'Private Car');
    await _choose(tester, 'Select make', 'Mahindra');
    await _choose(tester, 'Select model', 'Scorpio-N');
    await _choose(tester, 'Select variant', 'Z8');
    expect(find.text('Scorpio-N'), findsOneWidget);
    expect(find.text('Z8'), findsOneWidget);

    await _choose(tester, 'Mahindra', 'Tata');

    expect(find.text('Scorpio-N'), findsNothing);
    expect(find.text('Z8'), findsNothing);
    expect(find.text('Select model'), findsOneWidget);
    expect(find.text('Select model first'), findsOneWidget);
  });

  testWidgets('the market value is filled in from what is selected', (
    tester,
  ) async {
    await _pumpPage(tester);

    await tester.tap(find.text('Valuation'));
    await tester.pumpAndSettle();
    expect(_idvText(tester), isEmpty);

    await _choose(tester, 'Select product', 'Private Car');
    await _choose(tester, 'Select make', 'Mahindra');
    await _choose(tester, 'Select model', 'Scorpio-N');
    await _choose(tester, 'Select variant', 'Z8');

    // Still no value without a manufacturing year.
    expect(_idvText(tester), isEmpty);

    await tester.tap(find.text('Select manufacturing year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2023'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expected = estimateMarketValue(
      product: 'Private Car',
      make: 'Mahindra',
      model: 'Scorpio-N',
      variant: 'Z8',
      manufactured: DateTime(2023, now.month),
      now: now,
    )!;
    expect(_idvText(tester), '${expected.value}');

    // A cheaper variant gives a lower value straight away.
    await _choose(tester, 'Z8', 'Z2');
    final cheaper = estimateMarketValue(
      product: 'Private Car',
      make: 'Mahindra',
      model: 'Scorpio-N',
      variant: 'Z2',
      manufactured: DateTime(2023, now.month),
      now: now,
    )!;
    expect(_idvText(tester), '${cheaper.value}');
    expect(cheaper.value, lessThan(expected.value));
  });
}
