import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/app.dart';

void main() {
  testWidgets('App boots to the PreinspectionAgent login screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: PreinspectionAgentApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    // This app is the preinspection portal, so the tabs pick who is signing
    // in rather than which portal to enter.
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Surveyor'), findsOneWidget);
  });

  testWidgets('the dashboard greets the signed-in id and its role', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: PreinspectionAgentApp()),
    );
    await tester.pumpAndSettle();

    // Sign in as a surveyor: pick the tab, then fill the form.
    await tester.tap(find.text('Surveyor'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'SURV-4821');
    await tester.enterText(fields.at(1), 'secret');
    // The captcha field is validated against the code the page generated, so
    // read it back off the screen rather than guessing. "Agent" is five
    // letters too, hence skipping the page's own labels.
    const labels = {'Agent', 'Surveyor', 'Login'};
    final captcha = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .firstWhere(
          (d) =>
              d != null &&
              !labels.contains(d) &&
              RegExp(r'^[A-Za-z0-9]{5}$').hasMatch(d),
        )!;
    await tester.enterText(fields.at(2), captcha);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // We are on the dashboard...
    expect(find.text('Total Preinspection'), findsOneWidget);
    // ...greeted by the id that was typed in (the greeting is a Text.rich, so
    // the finder has to look inside the span) and the role its tab selected.
    expect(
      find.textContaining('SURV-4821', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Pre-Inspection Surveyor'), findsOneWidget);
    // The hardcoded workshop name is gone.
    expect(
      find.textContaining('XYZ Automobiles', findRichText: true),
      findsNothing,
    );
  });
}
