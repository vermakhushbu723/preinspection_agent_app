import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:preinspection_agent_app/core/widgets/document_picker_modal.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/presentation/document_upload/document_upload_page.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/state/claim_flow_provider.dart';

Widget _wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

/// The page is a lazily-built ListView, so a default 800x600 test surface
/// only ever builds the first few document cards. Give it a tall viewport so
/// every card is laid out and its badge can be asserted on.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('document upload status', () {
    testWidgets('every document reads Pending before anything is uploaded', (
      tester,
    ) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap(const DocumentUploadPage()));
      await tester.pump();

      expect(find.text('Pending'), findsNWidgets(6));
      expect(find.text('Submitted'), findsNothing);
      // Progress line reflects the same state.
      expect(find.text('0 / 6'), findsOneWidget);
    });

    testWidgets('a document flips to Submitted once its upload is recorded', (
      tester,
    ) async {
      _useTallSurface(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(claimFlowProvider.notifier)
          .addDocumentUpload('policy_copy', '/tmp/policy_copy_front.jpg');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DocumentUploadPage()),
        ),
      );
      await tester.pump();

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Pending'), findsNWidgets(5));
      expect(find.text('1 / 6'), findsOneWidget);
    });
  });

  group('document picker modal', () {
    testWidgets(
      'front/back sheet offers a Save button, disabled until a side is captured',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DocumentPickerModal(
                docName: 'Driving License',
                mode: DocPickerMode.frontBack,
                source: ImageSource.camera,
                onSaveSides: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Front Side'), findsOneWidget);
        expect(find.text('Back Side'), findsOneWidget);

        final saveButton = find.widgetWithText(ElevatedButton, 'Save');
        expect(saveButton, findsOneWidget);
        // Nothing captured yet -> Save stays disabled so nothing can be
        // recorded (and no document can flip to Submitted) by accident.
        expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
      },
    );
  });
}
