/// Where the app's backend lives: admin-service in ai-damage-assessment-service
/// (the same server the IBima Assist Admin panel uses, so whatever an agent
/// submits shows up there under Pre-Inspections).
///
/// Override per build, e.g. for a local backend on an Android emulator:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8040/api/v1
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://admin.ibimaassist.online/api/v1',
  );

  /// Origin for the signed file links the API returns (`/api/v1/media/...`).
  static String get origin => Uri.parse(baseUrl).origin;

  static const Duration timeout = Duration(seconds: 30);

  /// Videos can take a while on mobile data.
  static const Duration uploadTimeout = Duration(minutes: 5);
}
