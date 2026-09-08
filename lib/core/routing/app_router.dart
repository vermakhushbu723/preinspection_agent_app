import 'package:go_router/go_router.dart';

import '../../features/preinspection_agent/presentation/add_damage_photos/add_damage_photos_page.dart';
import '../../features/preinspection_agent/presentation/add_others_photos/add_others_photos_page.dart';
import '../../features/preinspection_agent/presentation/camera_capture/camera_capture_page.dart';
import '../../features/preinspection_agent/presentation/claim_start/claim_start_page.dart';
import '../../features/preinspection_agent/presentation/customer_declaration/customer_declaration_page.dart';
import '../../features/preinspection_agent/presentation/damage_review/damage_review_page.dart';
import '../../features/preinspection_agent/presentation/dashboard/dashboard_page.dart';
import '../../features/preinspection_agent/presentation/document_upload/document_upload_page.dart';
import '../../features/preinspection_agent/presentation/inspection_details/inspection_details_page.dart';
import '../../features/preinspection_agent/presentation/inspector_declaration/inspector_declaration_page.dart';
import '../../features/preinspection_agent/presentation/login/login_page.dart';
import '../../features/preinspection_agent/presentation/owner_vehicle_details/owner_vehicle_details_page.dart';
import '../../features/preinspection_agent/presentation/photo_capture_selection/photo_capture_selection_page.dart';
import '../../features/preinspection_agent/presentation/reinspection_photos/reinspection_photos_page.dart';
import '../../features/preinspection_agent/presentation/repair_submission/repair_submission_page.dart';
import '../../features/preinspection_agent/presentation/submitted/submitted_page.dart';
import '../../features/preinspection_agent/presentation/vehicle_information/vehicle_information_page.dart';
import '../../features/preinspection_agent/presentation/walk_around_video/walk_around_video_page.dart';
import 'app_routes.dart';

/// Builds a fresh GoRouter config for the PreinspectionAgent flow. Route list
/// order mirrors `src/pages/flows/preinspection/PreinspectionAgent/routesConfig.jsx`.
///
/// A function rather than a bare singleton so widget tests can each get
/// their own instance — reusing one `GoRouter` (and its internal
/// `Navigator` GlobalKey) across multiple `pumpWidget` calls in the same
/// test file causes "Duplicate GlobalKey" element-tree corruption.
GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: AppRoutes.claimStart,
      builder: (context, state) => const ClaimStartPage(),
    ),
    GoRoute(
      path: AppRoutes.ownerVehicleDetails,
      builder: (context, state) => const OwnerVehicleDetailsPage(),
    ),
    GoRoute(
      path: AppRoutes.documentUpload,
      builder: (context, state) => const DocumentUploadPage(),
    ),
    GoRoute(
      path: AppRoutes.inspectionDetails,
      builder: (context, state) => const InspectionDetailsPage(),
    ),
    GoRoute(
      path: AppRoutes.photoCaptureSelection,
      builder: (context, state) => const PhotoCaptureSelectionPage(),
    ),
    GoRoute(
      path: AppRoutes.cameraCapture,
      builder: (context, state) {
        final angle = state.pathParameters['angle']!;
        return CameraCapturePage(angle: angle);
      },
    ),
    GoRoute(
      path: AppRoutes.walkAroundVideo,
      builder: (context, state) => const WalkAroundVideoPage(),
    ),
    GoRoute(
      path: AppRoutes.addDamagePhotos,
      builder: (context, state) => const AddDamagePhotosPage(),
    ),
    GoRoute(
      path: AppRoutes.addOthersPhotos,
      builder: (context, state) => const AddOthersPhotosPage(),
    ),
    GoRoute(
      path: AppRoutes.damageReview,
      builder: (context, state) => const DamageReviewPage(),
    ),
    GoRoute(
      path: AppRoutes.submitted,
      builder: (context, state) => const SubmittedPage(),
    ),
    GoRoute(
      path: AppRoutes.reinspectionPhotos,
      builder: (context, state) => const ReinspectionPhotosPage(),
    ),
    GoRoute(
      path: AppRoutes.repairSubmission,
      builder: (context, state) => const RepairSubmissionPage(),
    ),
    GoRoute(
      path: AppRoutes.vehicleInformation,
      builder: (context, state) => const VehicleInformationPage(),
    ),
    GoRoute(
      path: AppRoutes.customerDeclaration,
      builder: (context, state) => const CustomerDeclarationPage(),
    ),
    GoRoute(
      path: AppRoutes.inspectorDeclaration,
      builder: (context, state) => const InspectorDeclarationPage(),
    ),
  ],
);

/// Single shared instance used by the running app (see `app.dart`).
final GoRouter appRouter = createAppRouter();
