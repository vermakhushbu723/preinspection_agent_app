import 'package:flutter/material.dart';

/// Reference thumbnails for the odometer / chassis-number / video cards on
/// PhotoCaptureSelectionPage — what a good shot of each looks like.
///
/// These are drawn rather than shipped as photographs: the only artwork the
/// project has for these slots is thin red line art that reads as a scribble
/// at thumbnail size, and stock photos would bring a licensing question with
/// them. To use real photos instead, drop three files into
/// `assets/images/guides/` (`odometer.jpg`, `chassis_number.jpg`,
/// `video.jpg`), declare the folder in `pubspec.yaml` and swap the `switch`
/// in [GuideThumbnail] for an `Image.asset` — nothing else has to change.
class GuideThumbnail extends StatelessWidget {
  const GuideThumbnail({super.key, required this.id});

  /// Capture-point id: `odometer`, `chassis-number` or `video`.
  final String id;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: switch (id) {
        'odometer' => _OdometerPainter(),
        'chassis-number' => _ChassisPlatePainter(),
        _ => _VideoFramePainter(),
      },
      child: const SizedBox.expand(),
    );
  }
}

/// An instrument cluster at night: two dial arcs and a lit odometer reading.
class _OdometerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1F2430));

    final dialPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.055
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5B6472);

    final radius = size.height * 0.30;
    for (final cx in [size.width * 0.26, size.width * 0.74]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, size.height * 0.44), radius: radius),
        3.6, // start a little past nine o'clock
        4.4,
        false,
        dialPaint,
      );
      // Needle.
      canvas.drawLine(
        Offset(cx, size.height * 0.44),
        Offset(cx - radius * 0.55, size.height * 0.44 + radius * 0.45),
        Paint()
          ..color = const Color(0xFFEF4444)
          ..strokeWidth = size.height * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }

    _paintText(
      canvas,
      size,
      '25876 km',
      Offset(size.width * 0.5, size.height * 0.80),
      TextStyle(
        color: const Color(0xFF7DD3FC),
        fontSize: size.height * 0.20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A stamped chassis plate: brushed metal with the VIN punched into it.
class _ChassisPlatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9AA1A9), Color(0xFF6B727A), Color(0xFF8B929A)],
        ).createShader(rect),
    );

    // Brushed-metal streaks.
    final streak = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (var y = size.height * 0.12; y < size.height; y += size.height * 0.16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streak);
    }

    // Punched plate area.
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.32,
        size.width * 0.84,
        size.height * 0.36,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFF4B5158));

    _paintText(
      canvas,
      size,
      'MA3WB1251L1234567',
      Offset(size.width * 0.5, size.height * 0.50),
      TextStyle(
        color: const Color(0xFFE5E7EB),
        fontSize: size.height * 0.17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A frame from a walk-around clip: road and sky behind a play button.
class _VideoFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6EA8DC), Color(0xFFBFD4E6), Color(0xFF4B5563)],
          stops: [0.0, 0.45, 0.46],
        ).createShader(rect),
    );

    // Lane markings running toward the horizon.
    final lane = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = size.height * 0.05
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.60 + i * 0.15);
      final half = size.width * (0.06 + i * 0.05);
      canvas.drawLine(
        Offset(size.width * 0.5 - half, y),
        Offset(size.width * 0.5 + half, y),
        lane,
      );
    }

    // Play button.
    final centre = Offset(size.width * 0.5, size.height * 0.48);
    final r = size.height * 0.22;
    canvas.drawCircle(centre, r, Paint()..color = const Color(0xE6FFFFFF));
    final triangle = Path()
      ..moveTo(centre.dx - r * 0.32, centre.dy - r * 0.45)
      ..lineTo(centre.dx + r * 0.50, centre.dy)
      ..lineTo(centre.dx - r * 0.32, centre.dy + r * 0.45)
      ..close();
    canvas.drawPath(triangle, Paint()..color = const Color(0xFF1D4ED8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws [text] centred on [centre], scaled down if it would overflow the
/// thumbnail's width.
void _paintText(
  Canvas canvas,
  Size size,
  String text,
  Offset centre,
  TextStyle style,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  final maxWidth = size.width * 0.88;
  final scale = painter.width > maxWidth ? maxWidth / painter.width : 1.0;

  canvas.save();
  canvas.translate(centre.dx, centre.dy);
  canvas.scale(scale);
  painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  canvas.restore();
}
