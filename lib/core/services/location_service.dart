import 'package:geolocator/geolocator.dart';

/// Wraps `geolocator` for the lat/long overlay shown during photo and video
/// capture (mirrors the web app's `navigator.geolocation.getCurrentPosition`
/// usage in `CameraCapturePage.jsx` / `WalkAroundVideoPage.jsx`).
class LocationService {
  /// How long to wait for a fresh fix before settling for the last known one.
  /// Indoors a high-accuracy fix can take a minute or never arrive at all.
  static const Duration fixTimeout = Duration(seconds: 8);

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: fixTimeout,
          ),
        );
      } catch (_) {
        // No fresh fix in time -- the last known position is still far
        // better than showing nothing.
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  String formatCoordinates(Position? position) {
    if (position == null) return 'Location unavailable';
    return '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}';
  }
}
