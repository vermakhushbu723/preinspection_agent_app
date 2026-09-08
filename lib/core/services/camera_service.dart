import 'package:camera/camera.dart';

/// Lifecycle helper around the `camera` package, shared by
/// `CameraCapturePage` (photos) and `WalkAroundVideoPage` (scripted video).
class CameraService {
  List<CameraDescription> _cameras = [];
  CameraController? controller;

  Future<CameraController> initialize({
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    _cameras = await availableCameras();
    final back = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    final ctrl = CameraController(
      back,
      resolution,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await ctrl.initialize();
    controller = ctrl;
    return ctrl;
  }

  Future<void> dispose() async {
    await controller?.dispose();
    controller = null;
  }
}
