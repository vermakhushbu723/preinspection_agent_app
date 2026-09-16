import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/orientation.dart';
import '../../data/vehicle_assets.dart';
import '../../state/claim_flow_provider.dart';

/// Live camera capture for a single angle/slot. Port of
/// `CameraCapturePage.jsx` (route `:angle`).
///
/// The web version fakes a "peripheral blur" cutout around the silhouette
/// guide via a hand-rolled flood-fill alpha mask (only needed because CSS
/// backdrop-blur has no native cutout primitive); natively we just layer a
/// translucent guide image over the live preview, which reads the same to
/// the user ("aim the vehicle within this outline").
///
/// The outline is only shown for the fixed 360-degree angles. Damage shots
/// and close-ups (odometer, chassis plate, dashboard, tyres…) get a plain
/// portrait viewfinder.
class CameraCapturePage extends ConsumerStatefulWidget {
  const CameraCapturePage({super.key, required this.angle});

  final String angle;

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage>
    with WidgetsBindingObserver {
  final _cameraService = CameraService();
  final _locationService = LocationService();
  final _mediaStorage = MediaStorageService();

  CameraController? _controller;
  Position? _position;
  bool _locating = true;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String? _capturedPath;
  bool _starting = true;
  bool _capturing = false;
  String? _error;

  /// Bumped every time the camera is (re)started or torn down, so a slow
  /// `initialize()` that finishes after the page was paused or left can tell
  /// it is stale and must not install its controller.
  int _generation = 0;

  /// Strips a numeric suffix like `-1` so `front-side-1`, `front-side-2`
  /// all resolve to the same guide image (mirrors the web app's angle
  /// suffix handling for multi-photo sides).
  String get _baseAngle => widget.angle.replaceAll(RegExp(r'-\d+$'), '');

  /// Damage shots (`front-damage-1`, `additional-damage-0`, ...) are
  /// free-form close-ups, unlike the fixed 360-degree angles.
  bool get _isDamageShot => widget.angle.contains('damage');

  /// Only the fixed 360-degree angles get the silhouette guide (and the
  /// landscape lock that goes with framing a whole vehicle).
  bool get _hasGuide =>
      !_isDamageShot && VehicleAssets.isGuidedAngle(_baseAngle);

  /// `front-side` -> `Front Side`. Port of `formatAngleName` in
  /// `CameraCapturePage.jsx`.
  String get _formattedAngle => widget.angle
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _startCamera();
    // Location is fetched alongside, never before, the camera: waiting on a
    // GPS fix first is what left this screen on a spinner indoors.
    _fetchLocation();
  }

  Future<void> _startCamera() async {
    final generation = ++_generation;
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      // Rotate the UI first, so the preview is laid out for the orientation
      // it will actually be shown in.
      if (_hasGuide) {
        await AppOrientation.lockLandscape();
      } else {
        await AppOrientation.lockPortrait();
      }

      final controller = await _cameraService.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }

      // Pin the capture orientation to the screen's, otherwise the preview
      // (and the saved photo) follow the phone's physical tilt and come out
      // sideways whenever the phone is held differently from the UI.
      final captureOrientation = _captureOrientationFor(controller);
      if (_hasGuide) {
        await SystemChrome.setPreferredOrientations([captureOrientation]);
      }
      try {
        await controller.lockCaptureOrientation(captureOrientation);
      } catch (_) {
        // Not every device supports it; the preview still works, it just
        // follows the phone's tilt. Not worth failing the whole camera over.
      }

      if (!mounted || generation != _generation) return;
      setState(() {
        _controller = controller;
        _starting = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = _describeError(e);
        _starting = false;
      });
    }
  }

  /// Portrait shots are always upright. Landscape shots keep whichever way
  /// round the phone is already held (it just came from the landscape photo
  /// guide), so entering the camera never flips the screen upside down.
  DeviceOrientation _captureOrientationFor(CameraController controller) {
    if (!_hasGuide) return DeviceOrientation.portraitUp;
    final physical = controller.value.deviceOrientation;
    return physical == DeviceOrientation.landscapeRight
        ? DeviceOrientation.landscapeRight
        : DeviceOrientation.landscapeLeft;
  }

  Future<void> _fetchLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _position = position;
      _locating = false;
    });
  }

  Future<void> _stopCamera() async {
    _generation++;
    _controller = null;
    // The service owns the controller it created; disposing it here is the
    // only release needed.
    await _cameraService.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera must be released while the app is in the background and
    // re-opened on return; otherwise the preview comes back black or frozen.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_controller != null) {
        _stopCamera();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null &&
          _capturedPath == null &&
          _error == null &&
          !_starting) {
        _startCamera();
      }
    }
  }

  String _describeError(Object e) {
    final message = e.toString();
    if (message.contains('CameraAccessDenied') ||
        message.contains('NotAllowedError')) {
      return 'Camera permission denied. Please enable camera access in settings.';
    }
    if (message.contains('cameraNotFound') ||
        message.contains('NotFoundError')) {
      return 'No camera found on this device.';
    }
    return 'Unable to access the camera: $message';
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) setState(() => _capturedPath = file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not take the photo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _retake() {
    setState(() => _capturedPath = null);
    if (_controller == null) _startCamera();
  }

  Future<void> _save() async {
    final path = _capturedPath;
    if (path == null) return;
    final savedPath = await _mediaStorage.savePhoto(widget.angle, path);
    ref.read(claimFlowProvider.notifier).setPhoto(widget.angle, savedPath);
    if (mounted) context.pop(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _generation++;
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = ref
        .watch(claimFlowProvider)
        .ownerVehicleDetails
        .vehicleCategory;
    final controller = _controller;

    final Widget body;
    if (_capturedPath != null) {
      body = _PreviewView(
        path: _capturedPath!,
        onRetake: _retake,
        onSave: _save,
      );
    } else if (_error != null) {
      body = _ErrorView(
        message: _error!,
        onRetry: _startCamera,
        onBack: () => context.pop(false),
      );
    } else if (_starting ||
        controller == null ||
        !controller.value.isInitialized) {
      body = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else {
      body = _LiveView(
        controller: controller,
        guideAsset: _hasGuide
            ? VehicleAssets.angleImage(category, _baseAngle)
            : null,
        angleLabel: _formattedAngle,
        locationText: _locating
            ? 'Fetching location…'
            : _locationService.formatCoordinates(_position),
        now: _now,
        capturing: _capturing,
        onCapture: _capture,
        onBack: () => context.pop(false),
      );
    }

    return Scaffold(backgroundColor: Colors.black, body: body);
  }
}

class _LiveView extends StatelessWidget {
  const _LiveView({
    required this.controller,
    required this.guideAsset,
    required this.angleLabel,
    required this.locationText,
    required this.now,
    required this.capturing,
    required this.onCapture,
    required this.onBack,
  });

  final CameraController controller;
  final String? guideAsset;
  final String angleLabel;
  final String locationText;
  final DateTime now;
  final bool capturing;
  final VoidCallback onCapture;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final landscape = box.maxWidth > box.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Edge to edge: the preview used to sit letterboxed in the
            // middle of a black screen.
            _FullScreenPreview(controller: controller, landscape: landscape),
            if (guideAsset != null)
              IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: FractionallySizedBox(
                      widthFactor: 0.72,
                      heightFactor: 0.9,
                      child: Image.asset(
                        guideAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            // Scrims keep the overlay text readable on bright scenes.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x80000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x99000000),
                    ],
                    stops: [0.0, 0.22, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: landscape ? _landscapeControls() : _portraitControls(),
            ),
          ],
        );
      },
    );
  }

  /// Shutter on the right edge, where the thumb rests when holding the phone
  /// sideways; stamp bottom-left.
  Widget _landscapeControls() {
    return Stack(
      children: [
        Positioned(top: 16, left: 16, child: _BackButton(onTap: onBack)),
        Positioned(
          top: 22,
          left: 80,
          right: 120,
          child: _AngleLabel(label: angleLabel, alignment: TextAlign.right),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 130,
          child: _Stamp(locationText: locationText, now: now),
        ),
        Positioned(
          right: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: _ShutterButton(busy: capturing, onTap: onCapture),
          ),
        ),
      ],
    );
  }

  /// Shutter bottom-centre, the standard phone-camera position when upright.
  Widget _portraitControls() {
    return Stack(
      children: [
        Positioned(top: 12, left: 12, child: _BackButton(onTap: onBack)),
        Positioned(
          top: 20,
          left: 68,
          right: 16,
          child: _AngleLabel(label: angleLabel, alignment: TextAlign.right),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 120,
          child: _Stamp(locationText: locationText, now: now),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: _ShutterButton(busy: capturing, onTap: onCapture),
          ),
        ),
      ],
    );
  }
}

/// Fills the whole screen with the camera preview, cropping the overflow
/// rather than letterboxing it.
class _FullScreenPreview extends StatelessWidget {
  const _FullScreenPreview({required this.controller, required this.landscape});

  final CameraController controller;
  final bool landscape;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return Center(child: CameraPreview(controller));

    // `previewSize` is reported in the sensor's landscape orientation.
    final longSide = previewSize.longestSide;
    final shortSide = previewSize.shortestSide;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: landscape ? longSide : shortSide,
          height: landscape ? shortSide : longSide,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      ),
    );
  }
}

class _AngleLabel extends StatelessWidget {
  const _AngleLabel({required this.label, required this.alignment});

  final String label;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignment,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
      ),
    );
  }
}

/// Location + time stamp shown over the preview.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.locationText, required this.now});

  final String locationText;
  final DateTime now;

  static const _style = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 14,
              color: AppColors.btnPrimary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Location: $locationText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _style,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 14,
              color: AppColors.btnPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
              style: _style,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.btnPrimary, width: 4),
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.btnPrimary,
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.btnPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.path,
    required this.onRetake,
    required this.onSave,
  });

  final String path;
  final VoidCallback onRetake;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(path), fit: BoxFit.contain),
        Positioned(
          bottom: 34,
          left: 26,
          right: 26,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onRetake,
                    child: const Text(
                      'Retake',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btnPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onSave,
                    child: const Text(
                      'Save & Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 8),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Used to just close the page, same as "Go Back".
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btnPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
