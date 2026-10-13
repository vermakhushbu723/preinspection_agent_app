import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/app.dart';
import 'package:preinspection_agent_app/core/routing/app_router.dart';
import 'package:preinspection_agent_app/core/routing/app_routes.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/data/preinspection_api.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/claim.dart';

import 'support/fake_api.dart';

Widget _app(FakePreinspectionApi api) => ProviderScope(
  overrides: [preinspectionApiProvider.overrideWithValue(api)],
  child: const PreinspectionAgentApp(),
);

/// Fills the login form (captcha read back off the screen) and taps Login.
Future<void> _login(WidgetTester tester, String userId, String password) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), userId);
  await tester.enterText(fields.at(1), password);
  // "Agent" is five letters too, hence skipping the page's own labels.
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
}

void main() {
  testWidgets('App boots to the PreinspectionAgent login screen', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakePreinspectionApi()));
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

    final api = FakePreinspectionApi()
      ..inspections = const [
        Claim(
          id: 'PI-100007',
          insurerName: 'ABG Insurance',
          claimNumber: 'PI-100007',
          registrationNumber: 'GJ01AA1111',
          insuredName: 'Asha Mehta',
          status: 'Pending',
          vehicle: '',
          surveyDate: '2026-10-13',
          location: '',
          amount: '',
          inspectionStatus: 'Assigned',
        ),
      ];
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    // Sign in as a surveyor: pick the tab, then fill the form.
    await tester.tap(find.text('Surveyor'));
    await tester.pump();
    await _login(tester, 'SURV-4821', 'secret');

    // The server was asked, on the surveyor tab.
    expect(api.calls, contains('login SURV-4821 surveyor'));
    // The dashboard lists the cases assigned in the Admin panel.
    expect(find.text('PI-100007'), findsOneWidget);

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

  testWidgets('a refused login stays on the form and shows why', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The app shares one router; the previous test left it on the dashboard.
    appRouter.go(AppRoutes.login);
    final api = FakePreinspectionApi()
      ..loginError = 'Invalid user ID or password. 4 attempt(s) left.';
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await _login(tester, 'agent1', 'wrong');

    expect(
      find.text('Invalid user ID or password. 4 attempt(s) left.'),
      findsOneWidget,
    );
    expect(find.text('Total Preinspection'), findsNothing);
  });
}
