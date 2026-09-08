import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Brief "please rotate your device" fallback shown while an orientation
/// lock request is pending. The web app relies entirely on detect-and-prompt
/// (`OrientationGuard.jsx`) since browsers can't force-rotate; natively we
/// lock orientation directly via `AppOrientation` and only need this as a
/// short-lived fallback.
class RotateDevicePrompt extends StatelessWidget {
  const RotateDevicePrompt({super.key, this.message = 'Please rotate your device to landscape'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.rotateBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.screen_rotation, color: Colors.white, size: 56),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
