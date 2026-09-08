import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/app.dart';

void main() {
  testWidgets('App boots to the PreinspectionAgent login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PreinspectionAgentApp()));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('Pre-Inspection'), findsOneWidget);
  });
}
