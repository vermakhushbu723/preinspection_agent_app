import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preinspection_agent_app/features/preinspection_agent/domain/models/owner_vehicle_details.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/vehicle_category.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/domain/workflow_option.dart';
import 'package:preinspection_agent_app/features/preinspection_agent/state/claim_flow_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'setOwnerVehicleDetails updates state and derives vehicle category',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const details = OwnerVehicleDetails(
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

      container
          .read(claimFlowProvider.notifier)
          .setOwnerVehicleDetails(details);

      final state = container.read(claimFlowProvider);
      expect(state.ownerVehicleDetails.ownerName, 'Rahul Sharma');
      expect(state.ownerVehicleDetails.vehicleCategory, VehicleCategory.bike);
    },
  );

  test('photo add/remove updates the photo manifest', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(claimFlowProvider.notifier);
    notifier.setPhoto('front-side', '/tmp/front.jpg');
    expect(
      container.read(claimFlowProvider).photos['front-side'],
      '/tmp/front.jpg',
    );

    notifier.removePhoto('front-side');
    expect(
      container.read(claimFlowProvider).photos.containsKey('front-side'),
      isFalse,
    );
  });

  test('signatures must both be present before submit is allowed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(claimFlowProvider.notifier);
    expect(container.read(claimFlowProvider).bothSignaturesPresent, isFalse);

    notifier.setCustomerSignature(Uint8List.fromList([1, 2, 3]));
    expect(container.read(claimFlowProvider).bothSignaturesPresent, isFalse);

    notifier.setInspectorSignature(Uint8List.fromList([4, 5, 6]));
    expect(container.read(claimFlowProvider).bothSignaturesPresent, isTrue);
  });

  test('setWorkflowOption persists the chosen branch', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(claimFlowProvider.notifier)
        .setWorkflowOption(WorkflowOption.group2);
    expect(
      container.read(claimFlowProvider).workflowOption,
      WorkflowOption.group2,
    );
  });

  test('resetSession clears back to a fresh state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(claimFlowProvider.notifier);
    notifier.setPhoto('front-side', '/tmp/front.jpg');
    await notifier.setWorkflowOption(WorkflowOption.group1);

    await notifier.resetSession();

    final state = container.read(claimFlowProvider);
    expect(state.photos, isEmpty);
    expect(state.workflowOption, isNull);
  });
}
