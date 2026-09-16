import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/orientation.dart';
import '../../data/vehicle_assets.dart';
import '../../domain/vehicle_category.dart';
import '../../domain/workflow_option.dart';
import '../../state/claim_flow_provider.dart';
import '../../state/claim_flow_state.dart';
import 'guide_thumbnails.dart';

/// A numbered capture point on the ring around the vehicle.
class _PhotoPoint {
  const _PhotoPoint(this.id, this.label, this.number, this.top, this.left);

  final String id;
  final String label;

  /// Shooting order, shown inside the marker's badge.
  final int number;
  final double top; // fraction 0..1 of the diagram box
  final double left; // fraction 0..1 of the diagram box
}

/// The eight walk-around angles, each placed at the part of the vehicle it
/// photographs, and numbered in the order an agent walks round the vehicle.
///
/// Every centre image (car, bike, truck) is drawn in the same front-left
/// three-quarter view: the front faces the lower left, the rear is at the
/// upper right, and the long side you can see is the vehicle's **left** —
/// the project's own `Left.png` guide has the front on the left of the frame
/// in exactly that way. The right-hand side is the hidden far side, so its
/// markers sit up and to the left, behind the roof line:
///
/// ```
///              RH Side     Rear RH      Rear
///   Front RH                                    Rear LH
///              Front       Front LH     LH Side
/// ```
///
/// Odometer, chassis number and the walk-around video are not on the ring —
/// they are close-ups rather than positions around the vehicle, so they sit
/// in their own strip along the bottom.
const _ringPoints = [
  _PhotoPoint('front-side', 'Front', 1, 0.88, 0.14),
  _PhotoPoint('front-rh-side', 'Front RH', 2, 0.50, 0.03),
  _PhotoPoint('rh-side', 'RH Side', 3, 0.12, 0.14),
  _PhotoPoint('rear-rh-side', 'Rear RH', 4, 0.04, 0.50),
  _PhotoPoint('rear-side', 'Rear', 5, 0.12, 0.86),
  _PhotoPoint('rear-lh-side', 'Rear LH', 6, 0.50, 0.97),
  _PhotoPoint('lh-side', 'LH Side', 7, 0.88, 0.86),
  _PhotoPoint('front-lh', 'Front LH', 8, 0.96, 0.50),
];

/// The close-up shots and the walk-around video, shown as cards under the
/// diagram. Every vehicle type gets all three — a two-wheeler has a chassis
/// number to photograph just like a car does.
const _extraShots = [
  ('odometer', 'Odometer', 'Clear photo of reading'),
  ('chassis-number', 'Chassis Number', 'Clear photo of the plate'),
  ('video', 'Video', 'Walk around the vehicle'),
];

/// Port of `PhotoCaptureSelectionPage.jsx`, restyled as a photo-guide board:
/// the vehicle with numbered markers wired to it by leader lines, and the
/// odometer / chassis / video shots in a strip below.
class PhotoCaptureSelectionPage extends ConsumerStatefulWidget {
  const PhotoCaptureSelectionPage({super.key});

  @override
  ConsumerState<PhotoCaptureSelectionPage> createState() =>
      _PhotoCaptureSelectionPageState();
}

class _PhotoCaptureSelectionPageState
    extends ConsumerState<PhotoCaptureSelectionPage> {
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
    await AppOrientation.lockLandscape();
  }

  Future<void> _openVideo() async {
    await context.push(AppRoutes.walkAroundVideo);
    await AppOrientation.lockLandscape();
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
    if (size.width <= size.height) return _rotatePrompt();

    final flow = ref.watch(claimFlowProvider);
    final category = flow.ownerVehicleDetails.vehicleCategory;

    final points = _ringPoints
        .where((p) => VehicleAssets.isAngleSupported(category, p.id))
        .toList();

    final allDone =
        points.every((p) => flow.photos.containsKey(p.id)) &&
        _extraShots.every(
          (e) => e.$1 == 'video'
              ? flow.walkAroundVideoPath != null
              : flow.photos.containsKey(e.$1),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _VehicleDiagram(
                  category: category,
                  points: points,
                  flow: flow,
                  onTapPoint: _openCamera,
                ),
              ),
            ),
            _ExtrasStrip(
              flow: flow,
              onTapShot: (id) => id == 'video' ? _openVideo() : _openCamera(id),
              onNext: allDone
                  ? () => _next(flow.workflowOption ?? WorkflowOption.group1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rotatePrompt() {
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
              const Text(
                'Rotate Device',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
}

/// The vehicle with its numbered markers, each wired to it by a leader line
/// the way a printed photo guide draws them.
class _VehicleDiagram extends StatelessWidget {
  const _VehicleDiagram({
    required this.category,
    required this.points,
    required this.flow,
    required this.onTapPoint,
  });

  final VehicleCategory category;
  final List<_PhotoPoint> points;
  final ClaimFlowState flow;
  final ValueChanged<String> onTapPoint;

  /// Captions sit centred on their marker, so only half a caption's width
  /// has to be kept clear on each side — the wide pills beside each circle
  /// were what used to overlap each other and swallow the vehicle.
  static const double _captionWidth = 74;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final markerSize = (math.min(w, h) * 0.13).clamp(34.0, 52.0);

        final marginX = _captionWidth / 2 + 4;
        // Top-row captions sit above their marker and the rest below, so
        // reserve a caption's height on both edges.
        final marginY = markerSize / 2 + 10 + _MarkerCaption.height;
        final iw = w - 2 * marginX;
        final ih = h - 2 * marginY;

        return Stack(
          children: [
            Positioned(
              left: marginX,
              top: marginY,
              width: iw,
              height: ih,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Leader lines are painted first so they run under both the
                  // vehicle and the markers.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LeaderLinePainter(
                        points: points,
                        done: {
                          for (final p in points)
                            p.id: flow.photos.containsKey(p.id),
                        },
                        markerRadius: markerSize / 2,
                      ),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      VehicleAssets.centerImage(category),
                      fit: BoxFit.contain,
                      height: ih * 0.70,
                      width: iw * 0.62,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.directions_car, size: 96),
                    ),
                  ),
                  for (final point in points)
                    _Marker(
                      point: point,
                      boxWidth: iw,
                      boxHeight: ih,
                      size: markerSize,
                      captionWidth: _captionWidth,
                      done: flow.photos.containsKey(point.id),
                      onTap: () => onTapPoint(point.id),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Draws a thin line from each marker toward the vehicle at the centre.
class _LeaderLinePainter extends CustomPainter {
  _LeaderLinePainter({
    required this.points,
    required this.done,
    required this.markerRadius,
  });

  final List<_PhotoPoint> points;
  final Map<String, bool> done;
  final double markerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);

    for (final point in points) {
      final marker = Offset(point.left * size.width, point.top * size.height);
      final toCentre = centre - marker;
      final distance = toCentre.distance;
      if (distance == 0) continue;
      final unit = toCentre / distance;

      // Start just outside the marker circle and stop short of the centre so
      // the line reaches toward the vehicle instead of crossing over it.
      final start = marker + unit * (markerRadius + 2);
      final end = marker + unit * (distance * 0.60);

      final paint = Paint()
        ..color = (done[point.id] ?? false)
            ? const Color(0xFF22C55E).withValues(alpha: 0.75)
            : const Color(0xFF93C5FD)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      canvas.drawCircle(end, 2.5, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderLinePainter oldDelegate) =>
      oldDelegate.done != done || oldDelegate.markerRadius != markerRadius;
}

/// One numbered capture marker with its caption (above for the top row,
/// below for everything else).
class _Marker extends StatelessWidget {
  const _Marker({
    required this.point,
    required this.boxWidth,
    required this.boxHeight,
    required this.size,
    required this.captionWidth,
    required this.done,
    required this.onTap,
  });

  final _PhotoPoint point;
  final double boxWidth;
  final double boxHeight;
  final double size;
  final double captionWidth;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8);

    return Positioned(
      left: point.left * boxWidth - size / 2,
      top: point.top * boxHeight - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                done ? Icons.check : Icons.photo_camera,
                color: Colors.white,
                size: size * 0.44,
              ),
            ),
            // Order badge, as numbered in a printed guide.
            Positioned(
              top: -5,
              left: -5,
              child: Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  '${point.number}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            Positioned(
              // Top-row captions go above the marker: underneath, they would
              // run into the vehicle.
              top: point.top < 0.3 ? null : size + 2,
              // Clear of the number badge, which sticks out above the circle.
              bottom: point.top < 0.3 ? size + 8 : null,
              child: _MarkerCaption(
                label: point.label,
                color: color,
                width: captionWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerCaption extends StatelessWidget {
  const _MarkerCaption({
    required this.label,
    required this.color,
    required this.width,
  });

  static const double height = 16;

  final String label;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/// Odometer / chassis number / walk-around video cards plus the Next button.
/// Each card pairs the guide shot with the agent's own capture for that slot.
class _ExtrasStrip extends StatelessWidget {
  const _ExtrasStrip({
    required this.flow,
    required this.onTapShot,
    required this.onNext,
  });

  final ClaimFlowState flow;
  final ValueChanged<String> onTapShot;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      // IntrinsicHeight rather than a stretched Row: the strip sits in a
      // Column, so a stretch cross-axis has no height to stretch to.
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final shot in _extraShots)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ExtraCard(
                    id: shot.$1,
                    label: shot.$2,
                    caption: shot.$3,
                    capturedPath: shot.$1 == 'video'
                        ? flow.walkAroundVideoPath
                        : flow.photos[shot.$1],
                    onTap: () => onTapShot(shot.$1),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.btnPrimary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: Colors.white,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Next  →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraCard extends StatelessWidget {
  const _ExtraCard({
    required this.id,
    required this.label,
    required this.caption,
    required this.capturedPath,
    required this.onTap,
  });

  final String id;
  final String label;
  final String caption;

  /// The agent's own photo (or recorded video) for this slot, once taken.
  final String? capturedPath;
  final VoidCallback onTap;

  /// Deliberately short: this strip sits under the diagram, and every pixel
  /// it gives back goes to the vehicle above it.
  static const double _thumbHeight = 44;
  static const double _thumbWidth = 74;

  bool get _done => capturedPath != null;

  @override
  Widget build(BuildContext context) {
    final color = _done ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _done ? const Color(0xFF86EFAC) : const Color(0xFFDBEAFE),
          ),
        ),
        child: Row(
          children: [
            // What a good shot of this slot looks like -- replaced by the
            // agent's own photo once they have taken one.
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: _thumbWidth,
                height: _thumbHeight,
                child: _done && id != 'video'
                    ? Image.file(File(capturedPath!), fit: BoxFit.cover)
                    : GuideThumbnail(id: id),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          _done ? Icons.check : Icons.photo_camera,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _done ? 'Captured' : '($caption)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _done
                          ? const Color(0xFF16A34A)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
