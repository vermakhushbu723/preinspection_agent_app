import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';

/// Canvas-based signature capture. Port of
/// `src/components/common/SignaturePad.jsx`.
///
/// [value] holds the last-exported PNG bytes (or null when empty).
/// [onChanged] fires with the newly rendered PNG bytes after each stroke
/// ends, and with `null` when cleared.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.value,
    required this.onChanged,
    this.height = 120,
    this.placeholder = 'Please sign in this field',
    this.showClearButton = true,
    this.enabled = true,
  });

  final Uint8List? value;
  final ValueChanged<Uint8List?> onChanged;
  final double height;
  final String placeholder;
  final bool showClearButton;
  final bool enabled;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  bool get _isEmpty => _strokes.isEmpty && widget.value == null;

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _currentStroke = [details.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _currentStroke == null) return;
    setState(() => _currentStroke!.add(details.localPosition));
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (!widget.enabled) return;
    _currentStroke = null;
    final bytes = await _exportPng();
    if (bytes != null) widget.onChanged(bytes);
  }

  Future<Uint8List?> _exportPng() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                RepaintBoundary(
                  key: _repaintKey,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _SignaturePainter(_strokes),
                    ),
                  ),
                ),
                if (_isEmpty)
                  IgnorePointer(
                    child: Center(
                      child: Text(
                        widget.placeholder,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.showClearButton)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isEmpty ? null : _clear,
              child: const Text('Clear'),
            ),
          ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
