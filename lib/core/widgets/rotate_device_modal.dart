import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bottom_button.dart';

/// Rotate-device gate shown before landscape photo capture starts. Port of
/// `src/components/modals/RotateDeviceModal.jsx`.
class RotateDeviceModal extends StatelessWidget {
  const RotateDeviceModal({super.key, required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.rotateBg,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFF00A0FE)),
              ),
              child: const Icon(
                Icons.screen_rotation,
                size: 36,
                color: Color(0xFF00A0FE),
              ),
            ),
            const Text(
              'Rotate',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.rotateAccent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please Rotate Your Device & Turn On The Auto Rotation As The Photo '
              'Needs To Be Captured In Landscape Mode',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            BottomButton(label: 'Allow', onPressed: onAllow),
          ],
        ),
      ),
    );
  }
}
