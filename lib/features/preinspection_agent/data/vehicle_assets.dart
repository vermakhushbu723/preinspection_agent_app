import '../domain/vehicle_category.dart';

/// Capture-angle -> asset filename map, per vehicle category. Port of
/// `ANGLE_FILES` in `src/constants/vehicleAssets.js`.
///
/// A `null` entry means the image isn't shipped for that category (bikes
/// have no chassis-number plate asset).
const Map<VehicleCategory, Map<String, String?>> _angleFiles = {
  VehicleCategory.car: {
    'rear-rh-side': 'RearRight.png',
    'rear-side': 'Rear.png',
    'rear-lh-side': 'RearLeft.png',
    'rh-side': 'Right.png',
    'front-rh-side': 'FrontRight.png',
    'front-side': 'Front.png',
    'front-lh': 'FrontLeft.png',
    'lh-side': 'Left.png',
    'odometer': 'Odometer.png',
    'chassis-number': 'ChassisNumber.png',
    'video': 'car.png',
  },
  VehicleCategory.bike: {
    'rear-rh-side': 'Rearright.png',
    'rear-side': 'Rear.png',
    'rear-lh-side': 'RearLeft.png',
    'rh-side': 'Right.png',
    'front-rh-side': 'FrontRight.png',
    'front-side': 'Front.png',
    'front-lh': 'FrontLeft.png',
    'lh-side': 'Left.png',
    'odometer': 'Odometer.png',
    'chassis-number': null,
    'video': 'bike.png',
  },
  VehicleCategory.truck: {
    'rear-rh-side': 'Rearright.png',
    'rear-side': 'Rear.png',
    'rear-lh-side': 'RearLeft.png',
    'rh-side': 'Right.png',
    'front-rh-side': 'FrontRight.png',
    'front-side': 'Front.png',
    'front-lh': 'FrontLeft.png',
    'lh-side': 'Left.png',
    'odometer': 'Odometer.png',
    'chassis-number': 'ChassisNumber.png',
    'video': 'truck.png',
  },
};

/// Ordered list of capture points shown on PhotoCaptureSelectionPage
/// (excluding 'video', which routes to WalkAroundVideoPage instead of
/// CameraCapturePage) plus a human-readable label for each.
const List<(String id, String label)> capturePoints = [
  ('front-side', 'Front'),
  ('front-rh-side', 'Front Right'),
  ('rh-side', 'Right'),
  ('rear-rh-side', 'Rear Right'),
  ('rear-side', 'Rear'),
  ('rear-lh-side', 'Rear Left'),
  ('lh-side', 'Left'),
  ('front-lh', 'Front Left'),
  ('odometer', 'Odometer'),
  ('chassis-number', 'Chassis Number'),
  ('video', 'Walk-around Video'),
];

class VehicleAssets {
  VehicleAssets._();

  static String _basePath(VehicleCategory category) =>
      'assets/images/vehicles/${category.assetFolder}';

  /// Whole-vehicle silhouette shown as the centre image on
  /// PhotoCaptureSelectionPage, and as a fallback guide on CameraCapturePage.
  static String centerImage(VehicleCategory category) =>
      '${_basePath(category)}/${category.assetFolder}.png';

  /// Per-angle guide image, falling back to the centre silhouette when the
  /// angle isn't shipped for this category.
  static String angleImage(VehicleCategory category, String angleId) {
    final file = _angleFiles[category]?[angleId];
    if (file == null) return centerImage(category);
    return '${_basePath(category)}/$file';
  }

  /// Whether this category has a real guide image for [angleId] — used to
  /// hide unsupported photo points (e.g. chassis-number for bikes).
  static bool isAngleSupported(VehicleCategory category, String angleId) {
    return _angleFiles[category]?[angleId] != null;
  }

  /// Guide art for a close-up slot (odometer, chassis number), falling back
  /// to another category's artwork when this one doesn't ship it — a
  /// two-wheeler has a chassis plate to photograph even though the bike
  /// folder has no drawing of one.
  static String closeUpImage(VehicleCategory category, String angleId) {
    final own = _angleFiles[category]?[angleId];
    if (own != null) return '${_basePath(category)}/$own';
    final fallback = _angleFiles[VehicleCategory.car]![angleId];
    if (fallback == null) return centerImage(category);
    return '${_basePath(VehicleCategory.car)}/$fallback';
  }

  /// Slots that are a close-up of one part rather than a shot framing the
  /// whole vehicle. These get a plain portrait viewfinder — a whole-vehicle
  /// silhouette laid over an odometer or a chassis plate only gets in the way.
  static const Set<String> _closeUpAngles = {'odometer', 'chassis-number'};

  /// Whether [angleId] is one of the fixed 360-degree capture points, i.e.
  /// a shot the user is meant to frame a whole vehicle in.
  ///
  /// The close-ups above and the "add others photos" slots (`dashboard`,
  /// `open-hood`, `tyre-2`, `front-under-body`, …) are shots of one part, so
  /// overlaying a whole-vehicle silhouette on the viewfinder only got in the
  /// way — this is what keeps that overlay off those shots.
  static bool isGuidedAngle(String angleId) =>
      angleId != 'video' &&
      !_closeUpAngles.contains(angleId) &&
      _angleFiles[VehicleCategory.car]!.containsKey(angleId);
}
