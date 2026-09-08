import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/orientation.dart';
import '../../state/claim_flow_provider.dart';

class _Instruction {
  const _Instruction(this.section, this.sub, this.desc);
  final String section;
  final String sub;
  final String desc;
}

const _instructionSeconds = 10;

const _instructions = [
  _Instruction('WALK AROUND', 'Front + Number Plate',
      'Open the driver-side door, sit in the driver seat, and record the inside view of the front windshield clearly.'),
  _Instruction('WALK AROUND', 'Inside The Car',
      'Record both sides of the RC (Registration Certificate) clearly. (Mandatory)'),
  _Instruction('WALK AROUND', 'Inside The Car', 'Record the Insurance Policy clearly, if available.'),
  _Instruction('WALK AROUND', 'Inside The Car', 'Start the engine and record the odometer reading clearly.'),
  _Instruction('WALK AROUND', 'Inside The Car',
      'Open the bonnet, record the chassis number clearly, and capture the complete engine compartment.'),
  _Instruction('WALK AROUND', 'Out side The Car',
      'Take a close-up video of the damaged portion clearly from multiple angles.'),
  _Instruction('WALK AROUND', 'Out side The Car',
      'Walk around the vehicle and record all four sides — front, rear, left and right.'),
  _Instruction('WALK AROUND', 'Out side The Car', 'Record the rear of the vehicle including the number plate clearly.'),
];

final _totalSeconds = _instructionSeconds * _instructions.length;

String _formatClock(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Scripted 360°-walkaround video recorder. Port of
/// `WalkAroundVideoPage.jsx`.
class WalkAroundVideoPage extends ConsumerStatefulWidget {
  const WalkAroundVideoPage({super.key});

  @override
  ConsumerState<WalkAroundVideoPage> createState() => _WalkAroundVideoPageState();
}

class _WalkAroundVideoPageState extends ConsumerState<WalkAroundVideoPage> {
  final _cameraService = CameraService();
  final _locationService = LocationService();
  final _mediaStorage = MediaStorageService();

  CameraController? _controller;
  VideoPlayerController? _playbackController;
  Position? _position;
  Timer? _clockTimer;
  Timer? _elapsedTimer;
  Timer? _blinkTimer;
  DateTime _now = DateTime.now();
  int _elapsedSeconds = 0;
  bool _isRecording = false;
  bool _recBlink = true;
  String? _recordedPath;
  bool _initializing = true;
  String? _error;

  int get _currentStep => (_elapsedSeconds ~/ _instructionSeconds).clamp(0, _instructions.length - 1);

  @override
  void initState() {
    super.initState();
    AppOrientation.lockLandscape();
    _init();
  }

  Future<void> _init() async {
    try {
      _controller = await _cameraService.initialize(enableAudio: true);
    } catch (e) {
      setState(() => _error = 'Camera & mic permission denied. Allow access and try again.');
    }
    _position = await _locationService.getCurrentPosition();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _recBlink = !_recBlink);
    });
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.startVideoRecording();
    setState(() {
      _isRecording = true;
      _elapsedSeconds = 0;
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _totalSeconds) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _elapsedTimer?.cancel();
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    final file = await controller.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _recordedPath = file.path;
    });
    final playback = VideoPlayerController.file(File(file.path));
    await playback.initialize();
    await playback.play();
    setState(() => _playbackController = playback);
  }

  Future<void> _retake() async {
    await _playbackController?.dispose();
    setState(() {
      _playbackController = null;
      _recordedPath = null;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _save() async {
    final path = _recordedPath;
    if (path == null) return;
    final savedPath = await _mediaStorage.saveVideo('walk_around_video', path);
    ref.read(claimFlowProvider.notifier).setWalkAroundVideo(savedPath);
    if (mounted) context.pop(true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _elapsedTimer?.cancel();
    _blinkTimer?.cancel();
    _cameraService.dispose();
    _playbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initializing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text('Opening camera...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              )
            : _error != null
                ? _ErrorView(message: _error!, onBack: () => context.pop(false))
                : _playbackController != null
                    ? _PlaybackView(
                        controller: _playbackController!,
                        onRetake: _retake,
                        onSave: _save,
                      )
                    : _RecordingView(
                        controller: _controller!,
                        isRecording: _isRecording,
                        elapsedSeconds: _elapsedSeconds,
                        recBlink: _recBlink,
                        currentStep: _currentStep,
                        position: _position,
                        now: _now,
                        locationService: _locationService,
                        onStart: _startRecording,
                        onStop: _stopRecording,
                        onBack: () => context.pop(false),
                      ),
      ),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.controller,
    required this.isRecording,
    required this.elapsedSeconds,
    required this.recBlink,
    required this.currentStep,
    required this.position,
    required this.now,
    required this.locationService,
    required this.onStart,
    required this.onStop,
    required this.onBack,
  });

  final CameraController controller;
  final bool isRecording;
  final int elapsedSeconds;
  final bool recBlink;
  final int currentStep;
  final Position? position;
  final DateTime now;
  final LocationService locationService;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onBack;

  String get _geoTag {
    if (position == null) return 'Location: Not available';
    return 'Location: ${position!.latitude.toStringAsFixed(3)}°, ${position!.longitude.toStringAsFixed(3)}°';
  }

  String get _dateTime {
    final d = DateFormat('dd/MM/yyyy').format(now);
    final t = DateFormat('hh:mm a').format(now);
    return '$t, $d';
  }

  @override
  Widget build(BuildContext context) {
    final current = _instructions[currentStep];
    final stepLabel =
        '${current.section} - STEP ${(currentStep + 1).toString().padLeft(2, '0')}/${_instructions.length.toString().padLeft(2, '0')}';

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        Positioned(
          top: 26,
          left: 26,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SvgPicture.asset('assets/icons/rightlogo.svg', height: 44,
                placeholderBuilder: (_) => const SizedBox(height: 44, width: 44)),
          ),
        ),
        Positioned(
          top: 26,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: recBlink ? 1 : 0.25),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xD93C3C3C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_formatClock(elapsedSeconds),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 26,
          right: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(stepLabel,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(current.sub, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(current.desc,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date: $_dateTime', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(_geoTag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isRecording)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onStart,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEF4444), width: 5),
                  ),
                ),
              ),
            ),
          ),
        if (isRecording)
          Positioned(
            bottom: 100,
            right: 30,
            child: GestureDetector(
              onTap: onStop,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Stop & Finish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaybackView extends StatefulWidget {
  const _PlaybackView({required this.controller, required this.onRetake, required this.onSave});

  final VideoPlayerController controller;
  final VoidCallback onRetake;
  final Future<void> Function() onSave;

  @override
  State<_PlaybackView> createState() => _PlaybackViewState();
}

class _PlaybackViewState extends State<_PlaybackView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => controller.value.isPlaying ? controller.pause() : controller.play(),
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        Positioned(
          left: 26,
          right: 26,
          bottom: 106,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 2),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                    max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: (v) => controller.seekTo(Duration(milliseconds: v.round())),
                    activeColor: AppColors.btnPrimary,
                    inactiveColor: Colors.white24,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22),
                      onPressed: () => controller.value.isPlaying ? controller.pause() : controller.play(),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.replay, color: Colors.white, size: 18),
                      onPressed: () {
                        controller.seekTo(Duration.zero);
                        controller.play();
                      },
                    ),
                    Text(
                      '${_formatClock(position.inSeconds)} / ${duration.inSeconds > 0 ? _formatClock(duration.inSeconds) : '--:--'}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        controller.value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => controller.setVolume(controller.value.volume == 0 ? 1 : 0),
                    ),
                    SizedBox(
                      width: 80,
                      child: Slider(
                        value: controller.value.volume,
                        onChanged: (v) => controller.setVolume(v),
                        activeColor: AppColors.btnPrimary,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 34,
          left: 26,
          right: 26,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.onRetake,
                  child: const Text('Retake', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.btnPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.onSave,
                  child: const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 8),
            const Text('Camera Access Required',
                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 13, height: 1.6)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btnPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
