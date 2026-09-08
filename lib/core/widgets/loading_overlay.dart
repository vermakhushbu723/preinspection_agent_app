import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-screen loading spinner shown briefly between route transitions.
/// Port of `src/components/common/LoadingScreen.jsx`.
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  // A plain Timer-driven angle rather than a repeating AnimationController --
  // a never-completing controller left ticking across quick route
  // transitions is what causes "elapsedInSeconds" assertions under
  // widget-test's FakeAsync clock.
  Timer? _spinTimer;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _spinTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) setState(() => _angle += 0.06);
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgApp),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _angle,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.transparent, width: 4),
                        bottom: BorderSide(
                          color: Colors.transparent,
                          width: 4,
                        ),
                        left: BorderSide(color: Colors.transparent, width: 4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
