import 'dart:async';
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

/// The eight walk-around angles, numbered in shooting order. Odometer,
/// chassis number and the walk-around video are no longer markers on the
/// ring — they are close-ups rather than positions around the car, so they
/// sit in their own strip along the bottom.
const _ringPoints = [
  _PhotoPoint('front-side', 'Front', 1, 0.50, 0.06),
  _PhotoPoint('front-rh-side', 'Front RH', 2, 0.22, 0.20),
  _PhotoPoint('rh-side', 'RH Side', 3, 0.06, 0.46),
  _PhotoPoint('rear-rh-side', 'Rear RH', 4, 0.20, 0.80),
  _PhotoPoint('rear-side', 'Rear', 5, 0.50, 0.94),
  _PhotoPoint('rear-lh-side', 'Rear LH', 8, 0.80, 0.82),
  _PhotoPoint('lh-side', 'LH Side', 6, 0.94, 0.52),
  _PhotoPoint('front-lh', 'Front LH', 7, 0.80, 0.18),
];

/// The close-up shots and the walk-around video, shown as cards under the
/// diagram (matching the reference photo guide).
const _extraShots = [
  ('odometer', 'Odometer', 'Clear photo of reading'),
  ('chassis-number', 'Chassis Number', 'Clear photo of number plate'),
  ('video', 'Video', 'Walk around the vehicle'),
];

/// Port of `PhotoCaptureSelectionPage.jsx`, restyled as the "Photo Guide"
/// board: a titled header, the vehicle with numbered markers wired to it by
/// leader lines, and the odometer / chassis / video shots in a strip below.
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

    final points =
        _ringPoints.where((p) => VehicleAssets.isAngleSupported(category, p.id)).toList();
    final extras = _extraShots
        .where((e) => e.$1 == 'video' || VehicleAssets.isAngleSupported(category, e.$1))
        .toList();

    final allDone = points.every((p) => flow.photos.containsKey(p.id)) &&
        extras.every((e) => e.$1 == 'video'
            ? flow.walkAroundVideoPath != null
            : flow.photos.containsKey(e.$1));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _GuideHeader(category: category),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: _VehicleDiagram(
                  category: category,
                  points: points,
                  flow: flow,
                  onTapPoint: _openCamera,
                ),
              ),
            ),
            _ExtrasStrip(
              category: category,
              extras: extras,
              flow: flow,
              onTapShot: (id) => id == 'video' ? _openVideo() : _openCamera(id),
              onNext: allDone ? () => _next(flow.workflowOption ?? WorkflowOption.group1) : null,
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
}

/// Blue title band: `"<vehicle> – Photo Guide"` plus the one-line instruction.
class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.category});

  final VehicleCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2E7BE8)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.photo_camera, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${category.displayName} – Photo Guide',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please take clear and well-lit photos of all sides and important parts of your vehicle.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The vehicle with its numbered markers, each wired to the car by a leader
/// line the way the printed guide draws them.
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

  /// Room reserved around the marker ring so circles and their chips are
  /// never clipped by the edge of the page.
  static const double _chipWidth = 104;
  static const double _chipGap = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final markerSize = (math.min(w, h) * 0.115).clamp(38.0, 56.0);

        final marginX = markerSize / 2 + _chipGap + _chipWidth;
        final marginY = markerSize / 2 + 10;
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
                          for (final p in points) p.id: flow.photos.containsKey(p.id),
                        },
                        markerRadius: markerSize / 2,
                      ),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      VehicleAssets.centerImage(category),
                      fit: BoxFit.contain,
                      height: ih * 0.56,
                      width: iw * 0.46,
                      errorBuilder: (_, _, _) => const Icon(Icons.directions_car, size: 96),
                    ),
                  ),
                  for (final point in points)
                    _Marker(
                      point: point,
                      boxWidth: iw,
                      boxHeight: ih,
                      size: markerSize,
                      done: flow.photos.containsKey(point.id),
                      chipWidth: _chipWidth,
                      chipGap: _chipGap,
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
      // the line touches the car's edge instead of crossing over it.
      final start = marker + unit * (markerRadius + 2);
      final end = marker + unit * (distance * 0.62);

      final paint = Paint()
        ..color = (done[point.id] ?? false)
            ? const Color(0xFF22C55E).withValues(alpha: 0.75)
            : const Color(0xFF60A5FA)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      canvas.drawCircle(end, 3, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderLinePainter oldDelegate) =>
      oldDelegate.done != done || oldDelegate.markerRadius != markerRadius;
}

/// One numbered capture marker plus its label chip.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.point,
    required this.boxWidth,
    required this.boxHeight,
    required this.size,
    required this.done,
    required this.chipWidth,
    required this.chipGap,
    required this.onTap,
  });

  final _PhotoPoint point;
  final double boxWidth;
  final double boxHeight;
  final double size;
  final bool done;
  final double chipWidth;
  final double chipGap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8);
    // Markers on the left half hang their chip to the right and vice versa,
    // so a chip never runs off the edge of the board.
    final chipOnRight = point.left < 0.5;

    final chip = Container(
      width: chipWidth,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        point.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: chipOnRight ? TextAlign.left : TextAlign.right,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );

    return Positioned(
      left: point.left * boxWidth - size / 2,
      top: point.top * boxHeight - size / 2,
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: chipOnRight ? size + chipGap : null,
            right: chipOnRight ? null : size + chipGap,
            child: GestureDetector(onTap: onTap, child: chip),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2))],
              ),
              child: Icon(
                done ? Icons.check : Icons.photo_camera,
                color: Colors.white,
                size: size * 0.42,
              ),
            ),
          ),
          // Order badge, as numbered in the printed guide.
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Text(
                '${point.number}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Odometer / chassis number / walk-around video cards plus the Next button.
class _ExtrasStrip extends StatelessWidget {
  const _ExtrasStrip({
    required this.category,
    required this.extras,
    required this.flow,
    required this.onTapShot,
    required this.onNext,
  });

  final VehicleCategory category;
  final List<(String, String, String)> extras;
  final ClaimFlowState flow;
  final ValueChanged<String> onTapShot;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final shot in extras)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ExtraCard(
                  id: shot.$1,
                  label: shot.$2,
                  caption: shot.$3,
                  category: category,
                  done: shot.$1 == 'video'
                      ? flow.walkAroundVideoPath != null
                      : flow.photos.containsKey(shot.$1),
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
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Next  →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _ExtraCard extends StatelessWidget {
  const _ExtraCard({
    required this.id,
    required this.label,
    required this.caption,
    required this.category,
    required this.done,
    required this.onTap,
  });

  final String id;
  final String label;
  final String caption;
  final VehicleCategory category;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: done ? const Color(0xFF86EFAC) : const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 62,
                height: 44,
                child: id == 'video'
                    ? Container(
                        color: const Color(0xFFE0F2FE),
                        child: const Icon(Icons.play_circle_fill, color: Color(0xFF1D4ED8)),
                      )
                    : Image.asset(
                        VehicleAssets.angleImage(category, id),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: const Color(0xFFE5E7EB)),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(done ? Icons.check_circle : Icons.photo_camera, size: 14, color: color),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '($caption)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
