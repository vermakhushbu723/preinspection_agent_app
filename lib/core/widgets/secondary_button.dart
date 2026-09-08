import 'package:flutter/material.dart';

/// Outlined compact button. Port of
/// `src/components/common/SecondaryButton.jsx`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    this.label = 'Cancel',
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
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF01A0FE),
          disabledForegroundColor: const Color(0xFF01A0FE),
          side: const BorderSide(color: Color(0xFF01A0FE), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
