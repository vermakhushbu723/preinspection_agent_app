/// A single captured photo, keyed by capture "angle"/slot id (e.g.
/// `front-side`, `additional-damage-1`, `dashboard`). Replaces the web
/// app's `localStorage['damage_photos']` angle -> base64 map with a
/// path-on-disk reference (see `MediaStorageService`).
class CapturedPhoto {
  const CapturedPhoto({
    required this.key,
    required this.filePath,
    required this.capturedAt,
  });

  final String key;
  final String filePath;
  final DateTime capturedAt;

  CapturedPhoto copyWith({String? filePath, DateTime? capturedAt}) {
    return CapturedPhoto(
      key: key,
      filePath: filePath ?? this.filePath,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
