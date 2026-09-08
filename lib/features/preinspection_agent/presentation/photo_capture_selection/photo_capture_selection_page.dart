import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/orientation.dart';
import '../../data/vehicle_assets.dart';
import '../../domain/workflow_option.dart';
import '../../state/claim_flow_provider.dart';
import '../../state/claim_flow_state.dart';

enum _LabelPos { top, bottom, left, right }

class _PhotoPoint {
  const _PhotoPoint(this.id, this.label, this.top, this.left, this.labelPos);
  final String id;
  final String label;
  final double top; // fraction 0..1
  final double left; // fraction 0..1
  final _LabelPos labelPos;
}

const _allPhotoPoints = [
  _PhotoPoint('rh-side', 'RH Side', 0.10, 0.42, _LabelPos.top),
  _PhotoPoint('rear-rh-side', 'Rear RH Side', 0.20, 0.72, _LabelPos.top),
  _PhotoPoint('rear-side', 'Rear Side', 0.46, 0.80, _LabelPos.right),
  _PhotoPoint('rear-lh-side', 'Rear LH Side', 0.72, 0.80, _LabelPos.right),
  _PhotoPoint('lh-side', 'LH Side', 0.90, 0.63, _LabelPos.bottom),
  _PhotoPoint('front-lh', 'Front LH', 0.92, 0.46, _LabelPos.bottom),
  _PhotoPoint('chassis-number', 'Chassis Number', 0.90, 0.30, _LabelPos.bottom),
  _PhotoPoint('front-side', 'Front Side', 0.74, 0.18, _LabelPos.bottom),
  _PhotoPoint('odometer', 'Odometer', 0.50, 0.13, _LabelPos.left),
  _PhotoPoint('front-rh-side', 'Front RH Side', 0.26, 0.23, _LabelPos.left),
  _PhotoPoint('video', 'Video', 0.90, 0.03, _LabelPos.top),
];

/// Port of `PhotoCaptureSelectionPage.jsx`.
///
/// The web version measures the rendered silhouette's exact pixel rect via
/// `ResizeObserver` to aim a direction arrow from each point precisely at
/// the vehicle. Here each point instead points its arrow straight at the
/// container's centre, which reads the same to a user (an arrow toward the
/// car) without that per-frame geometry measurement.
class PhotoCaptureSelectionPage extends ConsumerStatefulWidget {
  const PhotoCaptureSelectionPage({super.key});

  @override
  ConsumerState<PhotoCaptureSelectionPage> createState() => _PhotoCaptureSelectionPageState();
}

class _PhotoCaptureSelectionPageState extends ConsumerState<PhotoCaptureSelectionPage> {
  // A plain Timer-driven angle rather than a repeating AnimationController:
  // this page can be pushed and popped quickly (camera capture round-trips),
  // and a never-completing AnimationController left ticking across those
  // transitions is what causes "elapsedInSeconds" assertions under
  // widget-test's FakeAsync clock.
  Timer? _spinTimer;
  double _spinAngle = 0;

  @override
  void initState() {
    super.initState();
    AppOrientation.lockLandscape();
    _spinTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) setState(() => _spinAngle += 0.06);
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCamera(String angleId) async {
    await context.push(AppRoutes.cameraCapturePath(angleId));
  }

  Future<void> _openVideo() async {
    await context.push(AppRoutes.walkAroundVideo);
  }

  Future<void> _next(WorkflowOption option) async {
    await ref.read(claimFlowProvider.notifier).setWorkflowOption(option);
    if (!mounted) return;
    context.go(
      // Both workflow options continue to Add Others Photos in the
      // preinspection flow (there is no separate damage-photo step here).
      AppRoutes.addOthersPhotos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    if (!isLandscape) {
      return Scaffold(
        body: Container(
          color: const Color(0xFF3B82F6),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_iphone, color: Colors.white, size: 64),
                const SizedBox(height: 24),
                const Text('Rotate Device',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text(
                  'Please rotate your device to landscape mode to capture vehicle photos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 32),
                Transform.rotate(
                  angle: _spinAngle,
                  child: const Icon(Icons.sync, color: Colors.white, size: 48),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final flow = ref.watch(claimFlowProvider);
    final category = flow.ownerVehicleDetails.vehicleCategory;
    final photoPoints = _allPhotoPoints
        .where((p) => p.id == 'video' || VehicleAssets.isAngleSupported(category, p.id))
        .toList();

    final allDone = photoPoints.every((p) {
      if (p.id == 'video') return flow.walkAroundVideoPath != null;
      return flow.photos.containsKey(p.id);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final vmin = math.min(w, h);
              final circleSize = (vmin * 0.135).clamp(46.0, 76.0);
              final centerImage = VehicleAssets.centerImage(category);

              // Both the vehicle and the marker ring are laid out inside the
              // SAME inset rect. Insetting only the markers (an earlier fix
              // for clipped edge labels) kept the car centred in the outer
              // box, which is what threw every marker off its intended spot
              // relative to the vehicle.
              final marginX = circleSize / 2 + _labelGap + _sideLabelWidth;
              final marginY = circleSize / 2 + _labelGap + _labelHeight + 4;
              final iw = w - 2 * marginX;
              final ih = h - 2 * marginY;

              return Stack(
                children: [
                  Positioned(
                    left: marginX,
                    top: marginY,
                    width: iw,
                    height: ih,
                    // Markers sit on the rim of this rect, so their circles and
                    // captions spill into the margin -- that margin is exactly
                    // why nothing gets clipped.
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Image.asset(
                            centerImage,
                            fit: BoxFit.contain,
                            height: ih * 0.54,
                            width: iw * 0.46,
                            errorBuilder: (_, _, _) => const Icon(Icons.directions_car, size: 96),
                          ),
                        ),
                        for (final point in photoPoints)
                          _buildMarker(point, iw, ih, circleSize, flow),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ElevatedButton(
                      onPressed: allDone
                          ? () => _next(flow.workflowOption ?? WorkflowOption.group1)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01A0FE),
                        disabledBackgroundColor: const Color(0xFF9CA3AF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Next →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Geometry of a marker's caption, used both to place the caption and to
  /// reserve the room a marker needs so nothing is ever clipped.
  static const double _sideLabelWidth = 84;
  static const double _labelGap = 5;
  static const double _labelHeight = 15;

  Widget _buildMarker(_PhotoPoint point, double w, double h, double circleSize, ClaimFlowState flow) {
    final isVideo = point.id == 'video';
    final isDone = isVideo ? flow.walkAroundVideoPath != null : flow.photos.containsKey(point.id);
    final color = isDone ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);

    final cx = point.left * w;
    final cy = point.top * h;

    return Positioned(
      left: cx - circleSize / 2,
      top: cy - circleSize / 2,
      width: circleSize,
      height: circleSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: isVideo ? _openVideo : () => _openCamera(point.id),
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isDone ? const Color(0x1A22C55E) : const Color(0x1A3B82F6),
              ),
              child: Icon(
                isVideo ? Icons.videocam : Icons.camera_alt,
                color: color,
                size: circleSize * 0.35,
              ),
            ),
          ),
          if (isDone)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E)),
                child: const Icon(Icons.check, size: 11, color: Colors.white),
              ),
            ),
          _buildLabel(point, color, circleSize),
        ],
      ),
    );
  }

  Widget _buildLabel(_PhotoPoint point, Color color, double circleSize) {
    final text = Text(
      point.label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.3),
    );
    // Offsets are derived from circleSize (a fixed 42 put the caption inside
    // the circle once the marker scaled up on a bigger screen).
    switch (point.labelPos) {
      case _LabelPos.top:
        return Positioned(bottom: circleSize + _labelGap, child: text);
      case _LabelPos.bottom:
        return Positioned(top: circleSize + _labelGap, child: text);
      case _LabelPos.left:
        return Positioned(
          right: circleSize + _labelGap,
          child: SizedBox(width: _sideLabelWidth, child: text),
        );
      case _LabelPos.right:
        return Positioned(
          left: circleSize + _labelGap,
          child: SizedBox(width: _sideLabelWidth, child: text),
        );
    }
  }
}
