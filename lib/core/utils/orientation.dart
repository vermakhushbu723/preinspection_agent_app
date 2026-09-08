import 'package:flutter/services.dart';

/// Orientation-lock helpers.
///
/// The web app fakes orientation locking by *detecting* the current
/// orientation and showing a "please rotate" overlay when it doesn't match
/// what a route needs (see `OrientationGuard.jsx` / `utils/orientation.js`),
/// because browsers can't reliably force-rotate a page. Natively we can just
/// lock the orientation directly, which is simpler and more reliable.
class AppOrientation {
  AppOrientation._();

  static Future<void> lockLandscape() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static Future<void> lockPortrait() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  static Future<void> unlock() {
    return SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}
