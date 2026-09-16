import 'package:flutter/material.dart';

/// Compact solid action button. Port of
/// `src/components/common/PrimaryButton.jsx` — used for things like the
/// Camera/Gallery buttons on document/photo screens. Unlike `BottomButton`,
/// the web version doesn't dim the color when disabled — only the cursor
/// changes — so this mirrors that (no `disabledBackgroundColor` override).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.label = 'Submit',
    required this.onPressed,
    this.disabled = false,
    this.width,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool disabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF01A0FE),
          disabledBackgroundColor: const Color(0xFF01A0FE),
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
