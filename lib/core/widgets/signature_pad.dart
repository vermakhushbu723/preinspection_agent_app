import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';

/// Drives a [SignaturePad] from its parent: clearing the ink, undoing the
/// last stroke, or exporting what is currently drawn.
///
/// Without this the surrounding card's Clear/Undo buttons could only push a
/// `null` into the caller's state — the strokes already painted on the pad
/// stayed on screen, which is what made those buttons look dead.
class SignaturePadController {
  _SignaturePadState? _state;

  void _attach(_SignaturePadState state) => _state = state;

  void _detach(_SignaturePadState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Whether nothing has been drawn yet.
  bool get isEmpty => _state?._isEmpty ?? true;

  /// Wipes every stroke and reports `null` through `onChanged`.
  void clear() => _state?.clearPad();

  /// Removes the most recent stroke and re-exports what is left.
  void undo() => _state?.undoStroke();

  /// Re-exports the current drawing (used by an explicit "Save" button).
  Future<Uint8List?> export() async => _state?.exportPng();
}

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
    this.controller,
    this.height = 120,
    this.placeholder = 'Please sign in this field',
    this.showClearButton = true,
    this.enabled = true,
  });

  final Uint8List? value;
  final ValueChanged<Uint8List?> onChanged;
  final SignaturePadController? controller;
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

  bool get _isEmpty => _strokes.isEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // The owner dropped the signature (e.g. it was cleared elsewhere, or the
    // flow was reset) -- drop the ink with it, otherwise the pad keeps
    // showing a signature the rest of the app no longer has.
    if (widget.value == null &&
        oldWidget.value != null &&
        _strokes.isNotEmpty) {
      setState(_strokes.clear);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

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
    final bytes = await exportPng();
    if (bytes != null) widget.onChanged(bytes);
  }

  Future<Uint8List?> exportPng() async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void clearPad() {
    if (_strokes.isEmpty && widget.value == null) return;
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    widget.onChanged(null);
  }

  Future<void> undoStroke() async {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _currentStroke = null;
    });
    if (_strokes.isEmpty) {
      widget.onChanged(null);
      return;
    }
    // Let the removed stroke actually leave the canvas before exporting,
    // otherwise the PNG still contains it.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final bytes = await exportPng();
    if (bytes != null) widget.onChanged(bytes);
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
                  // A plain GestureDetector loses every vertical stroke to the
                  // enclosing scroll view -- the list scrolled instead of the
                  // pen drawing, which is why signing appeared to do nothing.
                  // This recognizer claims the pointer as soon as it lands on
                  // the pad, so strokes always reach the canvas.
                  child: RawGestureDetector(
                    gestures: {
                      _PadPanGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            _PadPanGestureRecognizer
                          >(
                            () => _PadPanGestureRecognizer(debugOwner: this),
                            (recognizer) => recognizer
                              ..onStart = _onPanStart
                              ..onUpdate = _onPanUpdate
                              ..onEnd = _onPanEnd,
                          ),
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _SignaturePainter(_strokes),
                      child: const SizedBox.expand(),
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
              onPressed: _isEmpty ? null : clearPad,
              child: const Text('Clear'),
            ),
          ),
      ],
    );
  }
}

/// Pan recognizer that wins the gesture arena outright, so a signature
/// stroke is never stolen by a parent [Scrollable].
class _PadPanGestureRecognizer extends PanGestureRecognizer {
  _PadPanGestureRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) => acceptGesture(pointer);
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
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        // A tap with no drag is still a mark -- draw it as a dot rather than
        // silently swallowing it.
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
        continue;
      }
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
