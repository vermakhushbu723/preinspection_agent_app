import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preinspection_agent_app/core/routing/app_router.dart';
import 'package:preinspection_agent_app/core/routing/app_routes.dart';

const _staticRoutes = [
  AppRoutes.login,
  AppRoutes.dashboard,
  AppRoutes.claimStart,
  AppRoutes.ownerVehicleDetails,
  AppRoutes.documentUpload,
  AppRoutes.inspectionDetails,
  AppRoutes.photoCaptureSelection,
  AppRoutes.walkAroundVideo,
  AppRoutes.addDamagePhotos,
  AppRoutes.addOthersPhotos,
  AppRoutes.damageReview,
  AppRoutes.submitted,
  AppRoutes.reinspectionPhotos,
  AppRoutes.repairSubmission,
  AppRoutes.vehicleInformation,
  AppRoutes.customerDeclaration,
  AppRoutes.inspectorDeclaration,
];

void main() {
  testWidgets('every PreinspectionAgent route resolves to a page', (
    tester,
  ) async {
    // A fresh router per test -- reusing the shared `appRouter` singleton
    // (and its internal Navigator GlobalKey) across more than one
    // `pumpWidget` in the same test file corrupts the element tree.
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    for (final path in _staticRoutes) {
      router.go(path);
      // `pump` rather than `pumpAndSettle`: the camera/video capture screens
      // run a perpetual 1s clock-overlay timer, which would make
      // pumpAndSettle wait forever for animations to stop.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(Scaffold),
        findsWidgets,
        reason: 'route $path did not render a Scaffold',
      );
    }
  });

  testWidgets('camera-capture route accepts an angle path parameter', (
    tester,
  ) async {
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.cameraCapturePath('front-side'));
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
  });
}
