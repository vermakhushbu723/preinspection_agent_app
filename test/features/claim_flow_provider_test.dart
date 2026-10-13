import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preinspection_agent_app/core/services/api_client.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/data/preinspection_api.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/claim.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/owner_vehicle_details.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/vehicle_category.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/workflow_option.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/state/claim_flow_provider.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/state/claim_flow_state.dart';

import '../support/fake_api.dart';

const _details = OwnerVehicleDetails(
  surveyType: 'pre inspection',
  ownerName: 'Rahul Sharma',
  mobile: '9876543210',
  email: 'rahul@example.com',
  odometer: '12000',
  registrationNumber: 'OD02AB1234',
  state: 'Odisha',
  registrationDate: '01-01-2026',
  product: 'Two Wheeler',
  make: 'Honda',
  model: 'Activa',
  variant: 'Base',
  manufacturingYear: '01-2024',
  ownerSerialNumber: '2',
  idv: '450000',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePreinspectionApi api;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakePreinspectionApi();
    container = ProviderContainer(
      overrides: [preinspectionApiProvider.overrideWithValue(api)],
    );
  });
  tearDown(() => container.dispose());

  ClaimFlowNotifier notifier() => container.read(claimFlowProvider.notifier);
  ClaimFlowState flow() => container.read(claimFlowProvider);

  test('setOwnerVehicleDetails updates state and derives vehicle category', () {
    notifier().setOwnerVehicleDetails(_details);
    expect(flow().ownerVehicleDetails.ownerName, 'Rahul Sharma');
    expect(flow().ownerVehicleDetails.vehicleCategory, VehicleCategory.bike);
  });

  test(
    'saving the owner form starts the pre-inspection on the server',
    () async {
      await notifier().saveOwnerVehicleDetails(_details);
      expect(api.calls, contains('create OD02AB1234'));
      expect(flow().inspectionId, 'PI-100001');

      // A second save updates the same case.
      await notifier().saveOwnerVehicleDetails(_details);
      expect(api.calls, contains('patch PI-100001'));
    },
  );

  test('photo add/remove updates the photo manifest', () async {
    notifier().setPhoto('front-side', '/tmp/front.jpg');
    expect(flow().photos['front-side'], '/tmp/front.jpg');

    notifier().removePhoto('front-side');
    expect(flow().photos.containsKey('front-side'), isFalse);
  });

  test('captured photos upload in the background with their slot', () async {
    await notifier().saveOwnerVehicleDetails(_details);
    notifier().setPhoto(
      'front-side',
      '/tmp/front.jpg',
      latitude: 19.07,
      longitude: 72.87,
    );
    notifier().addDocumentUpload('rc', '/tmp/rc.jpg', slot: 'rc_front');
    await notifier().syncUploads();
    expect(
      api.uploaded,
      containsAll(['photo/front-side', 'document/rc_front']),
    );
    expect(flow().uploads['photo/front-side']!.status, UploadStatus.done);
  });

  test('a failed upload is retried before submit', () async {
    await notifier().saveOwnerVehicleDetails(_details);
    api.failUploads = 1;
    notifier().setPhoto('front-side', '/tmp/front.jpg');
    // Let the first attempt fail.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(flow().uploads['photo/front-side']!.status, UploadStatus.failed);

    await notifier().syncUploads();
    expect(flow().uploads['photo/front-side']!.status, UploadStatus.done);
  });

  test('sync reports files that still cannot be uploaded', () async {
    await notifier().saveOwnerVehicleDetails(_details);
    api.failUploads = 5;
    notifier().setPhoto('front-side', '/tmp/front.jpg');
    await expectLater(notifier().syncUploads(), throwsA(isA<ApiException>()));
  });

  test('signatures must both be present before submit is allowed', () {
    expect(flow().bothSignaturesPresent, isFalse);
    notifier().setCustomerSignature(Uint8List.fromList([1, 2, 3]));
    expect(flow().bothSignaturesPresent, isFalse);
    notifier().setInspectorSignature(Uint8List.fromList([4, 5, 6]));
    expect(flow().bothSignaturesPresent, isTrue);
  });

  test(
    'submitting the others branch sends signatures, declarations and recommendation',
    () async {
      await notifier().saveOwnerVehicleDetails(_details);
      await notifier().setWorkflowOption(WorkflowOption.group2);
      notifier()
        ..setCustomerSignature(Uint8List.fromList([1]))
        ..setInspectorSignature(Uint8List.fromList([2]))
        ..setCustomerDeclarationAccepted(true)
        ..setInspectorDeclarationAccepted(true);
      await notifier().submitSurvey(recommendation: 'Approved');

      expect(
        api.uploaded,
        containsAll(['signature/customer', 'signature/inspector']),
      );
      expect(api.patches['PI-100001'], containsPair('workflow', 'others'));
      expect(
        api.patches['PI-100001'],
        containsPair('agentRecommendation', 'Approved'),
      );
      expect(
        api.patches['PI-100001'],
        containsPair('customerDeclaration', true),
      );
      expect(api.calls, contains('submit PI-100001'));
      expect(flow().inspectionStatus, 'Submitted');
    },
  );

  test('opening an assigned case prefills the form from the server', () async {
    await notifier().openInspection(
      const Claim(
        id: 'PI-100009',
        insurerName: 'ABG',
        claimNumber: 'PI-100009',
        registrationNumber: 'GJ01AA1111',
        insuredName: 'Asha Mehta',
        status: 'Pending',
        vehicle: '',
        surveyDate: '',
        location: '',
        amount: '',
      ),
    );
    expect(flow().inspectionId, 'PI-100009');
    expect(flow().ownerVehicleDetails.ownerName, 'Asha Mehta');
    expect(flow().uploads['document/rc_front']!.status, UploadStatus.done);
  });

  test('setWorkflowOption persists the chosen branch', () async {
    await notifier().setWorkflowOption(WorkflowOption.group2);
    expect(flow().workflowOption, WorkflowOption.group2);
  });

  test('resetSession clears back to a fresh state', () async {
    notifier().setPhoto('front-side', '/tmp/front.jpg');
    await notifier().setWorkflowOption(WorkflowOption.group1);
    await notifier().resetSession();
    expect(flow().photos, isEmpty);
    expect(flow().workflowOption, isNull);
    expect(flow().inspectionId, isNull);
  });
}
