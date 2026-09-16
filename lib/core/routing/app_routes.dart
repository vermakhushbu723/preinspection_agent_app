/// Route path constants for the PreinspectionAgent flow.
///
/// Paths mirror the web app's `src/pages/flows/preinspection/PreinspectionAgent/routes.js`
/// 1:1 so the URL scheme stays recognizable across both apps.
class AppRoutes {
  AppRoutes._();

  static const String login = '/preinspection-agent/login';
  static const String dashboard = '/preinspection-agent/dashboard';
  static const String claimStart = '/preinspection-agent/claim-start';
  static const String ownerVehicleDetails =
      '/preinspection-agent/owner-vehicle-details';
  static const String documentUpload = '/preinspection-agent/document-upload';
  static const String inspectionDetails =
      '/preinspection-agent/inspection-details';
  static const String photoCaptureSelection =
      '/preinspection-agent/photo-capture-selection';

  /// Path param `angle` identifies which capture point/side is being shot.
  static const String cameraCapture =
      '/preinspection-agent/camera-capture/:angle';
  static String cameraCapturePath(String angle) =>
      '/preinspection-agent/camera-capture/$angle';

  static const String walkAroundVideo =
      '/preinspection-agent/walk-around-video';
  static const String addDamagePhotos =
      '/preinspection-agent/add-damage-photos';
  static const String addOthersPhotos =
      '/preinspection-agent/add-others-photos';
  static const String damageReview = '/preinspection-agent/damage-review';
  static const String submitted = '/preinspection-agent/submitted';
  static const String reinspectionPhotos =
      '/preinspection-agent/reinspection-photos';
  static const String repairSubmission =
      '/preinspection-agent/repair-submission';
  static const String vehicleInformation =
      '/preinspection-agent/vehicle-information';
  static const String customerDeclaration =
      '/preinspection-agent/customer-declaration';
  static const String inspectorDeclaration =
      '/preinspection-agent/inspector-declaration';
}
