import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves captured photos/videos to app-local storage.
///
/// Replaces the web app's `localStorage['damage_photos']` base64 map and
/// `localStorage['walk_around_video_url']` blob-URL (which doesn't even
/// survive a reload) with real files on disk, referenced by path from the
/// claim-flow state.
class MediaStorageService {
  static const String _sessionFolder = 'preinspection_agent_session';

  Future<Directory> _sessionDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _sessionFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies [sourcePath] into the session folder under a name derived from
  /// [key] (e.g. the capture angle), returning the saved file's path.
  Future<String> savePhoto(String key, String sourcePath) async {
    final dir = await _sessionDir();
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(
      sourcePath,
    );
    final dest = p.join(dir.path, '${_sanitize(key)}$ext');
    final saved = await File(sourcePath).copy(dest);
    return saved.path;
  }

  Future<String> saveVideo(String key, String sourcePath) async {
    final dir = await _sessionDir();
    final ext = p.extension(sourcePath).isEmpty ? '.mp4' : p.extension(
      sourcePath,
    );
    final dest = p.join(dir.path, '${_sanitize(key)}$ext');
    final saved = await File(sourcePath).copy(dest);
    return saved.path;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Wipes the whole session folder — mirrors the web app's
  /// `localStorage.clear()` calls on RepairSubmissionPage/ReinspectionPhotosPage.
  Future<void> clearSession() async {
    final dir = await _sessionDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  String _sanitize(String key) => key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
